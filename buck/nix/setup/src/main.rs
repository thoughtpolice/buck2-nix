//! An 'setup installer' for the project and build system. This largely just
//! automates installation of 'direnv' as well as using Sapling to clone the
//! repository, and warning the user of some gotchas.

// -----------------------------------------------------------------------------

#![deny(missing_docs)]
#![allow(unused_imports)]

use std::env;
use std::path::{Path, PathBuf};
use std::str::FromStr;
use std::time::Duration;
use std::{fmt::Display, thread};

use color_eyre::owo_colors::OwoColorize;
use color_eyre::{Help, Report};
use console::{style, Emoji, Term};
use dialoguer::Input;
use eyre::{eyre, Context, Result};
use tracing::{info, instrument, trace};

use dialoguer::{theme::ColorfulTheme, Confirm, Select};
use indicatif::ProgressIterator;

use cmd_lib::*;

use clap::{arg, Parser};

// -----------------------------------------------------------------------------

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
enum Scm {
    Git,
    Sapling,
    Jujutsu,
}

#[derive(Parser, Debug)]
#[command()]
struct Args {
    /// Path to the upstream source repository
    #[arg(
        short,
        long,
        default_value = "https://github.com/thoughtpolice/buck2-nix" // XXX FIXME (aseipp): hardcode 'buck2-nix' somewhere else?
    )]
    upstream: String,

    /// Name of the source repository checkout
    #[arg(short, long)]
    checkout_path: Option<String>,

    /// Source control system to clone the repository with
    #[arg(short, long)]
    scm: Option<Scm>,

    /// Skip confirmation prompt
    #[arg(long, action)]
    skip_confirm: bool,
}

fn main() -> Result<(), Report> {
    install_tracing();
    color_eyre::install()?;
    let args = Args::parse();

    let term = Term::stdout();
    term.clear_screen()?;

    trace!("Starting setup installer");

    let msg = format!(
        r#"{} Welcome to the setup installer for the project and build system.

    This installer tool largely automates installation of 'direnv' as well as
    using your chosen source code management tool to clone the repository, and
    warning the user of some gotchas.

    This is a work in progress, and may have bugs.

    You can quit at any time with {}"#,
        Emoji("👋 ", ""),
        style("Ctrl-C").underlined()
    );

    let theme = ColorfulTheme::default(); // XXX FIXME (aseipp): propagate
    if !args.skip_confirm
        && !Confirm::with_theme(&theme)
            .report(false)
            .with_prompt(format!("{}\n\n  Do you wish to continue?", msg))
            .interact()?
    {
        println!("OK, bye!");
        return Ok(());
    } else if args.skip_confirm {
        println!("{}", msg);
        println!("\n{} Skipping confirmation prompt", Emoji("👍 ", ""));
    }

    println!(
        "{} Performing pre-flight setup checks...\n",
        Emoji("🛫 ", "")
    );

    let actions: Vec<(&str, fn() -> Result<(), Report>, &str)> = vec![
        ("⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏", check_os, "Checking the operating system"),
        (
            "⠙⠹⠸⠼⠴⠦⠧⠇⠏⠋",
            check_nix_version,
            "Checking installed Nix version",
        ),
        (
            "⠹⠸⠼⠴⠦⠧⠇⠏⠋⠙",
            check_direnv,
            "Checking if direnv is installed",
        ),
        (
            "⠸⠼⠴⠦⠧⠇⠏⠋⠙⠹",
            check_trusted_users,
            "Checking for your $USER in Nix 'trusted-users'",
        ),
    ];

    // simulate a nice little interactive loop, for fun
    for (i, &(tick_chars, action, desc)) in actions.iter().enumerate() {
        let pb = indicatif::ProgressBar::new_spinner();
        pb.set_style(
            indicatif::ProgressStyle::default_spinner()
                .tick_chars(tick_chars)
                .template("{spinner:.green} {msg}")?,
        );
        let msg = |m| format!("[{}/{}] {}", i + 1, actions.len(), m);

        pb.set_message(msg(format!("{}...", desc)));
        pb.enable_steady_tick(Duration::from_millis(100));
        let result = action();
        thread::sleep(Duration::from_millis(500));
        pb.finish_with_message(msg(format!("{}... {}!", desc, style("OK").green())));
        println!();
        result?;
    }

    println!("\n{} {}\n", Emoji("🎉 ", ""), "Setup complete!");

    let full_checkout_path = if args.skip_confirm {
        if let Some(scm) = args.scm {
            clone_src(&args, &scm)
        } else {
            Err(eyre!("No SCM specified, and --skip-confirm was passed"))
                .wrap_err("You must specify a source control system to clone the repository with")
                .suggestion("use --scm")
        }
    } else {
        if let Some(scm) = args.scm {
            clone_src(&args, &scm)
        } else {
            let scm = choose_scm()?;
            clone_src(&args, &scm)
        }
    }?;

    match full_checkout_path {
        Some(path) => {
            println!(
        r#"{}{} {}

  You can now 'cd' into '{}' and begin developing!

  Upon doing so, {} will activate, populating your shell with the needed environment.
"#,
                Emoji("✔ ", "").green(),
                style("Finished!").bold(),
                Emoji("🎉 🎉 🎉", ""),
                style(path.display()).bold(),
                style("direnv").bold()
            );

            Ok(())
        },
        None => {
            println!("{}Aborted! No repository was cloned.", Emoji("✖ ", "").red());
            Ok(())
        }
    }


}

// -----------------------------------------------------------------------------
// -- Setup checks, direnv

const MSNV: &str = "2.14.0";

#[instrument]
fn check_os() -> Result<(), Report> {
    let (os, supported) = if cfg!(target_os = "linux") {
        ("Linux", true)
    } else if cfg!(target_os = "macos") {
        ("macOS", false /* XXX FIXME (aseipp): macOS support */)
    } else if cfg!(target_os = "windows") {
        ("Windows", false)
    } else {
        ("Unknown", false)
    };

    trace!(os, supported, "checking operating system");
    if !supported {
        return Err(eyre!("Unsupported operating system: {}", os)
            .wrap_err("This project (and installer) only supports Linux (for now)")
            .suggestion("use a Linux distribution"));
    }

    Ok(())
}

#[instrument]
fn check_nix_version() -> Result<(), Report> {
    let n = run_fun!(nix eval --raw --expr "builtins.nixVersion")?;
    let v = run_fun!(nix eval --expr "builtins.compareVersions \"${n}\" \"${MSNV}\"")?;
    trace!(
        msnv = MSNV,
        nixver = n,
        result = v,
        "checking nix compatbility",
    );

    match v.as_str() {
        "1" | "0" => Ok(()),
        "-1" => {
            // XXX FIXME (aseipp): upgrade nix for non-nixos users?
            return Err(eyre!("Incompatible Nix version: {}", n)
                .wrap_err(format!("Version {} is too old", n))
                .suggestion(format!("upgrade Nix to {} or later", MSNV)));
        }
        _ => {
            return Err(eyre!("Unexpected Nix version comparison result: {}", v)
                .wrap_err("This is a bug in the installer, please report it"));
        }
    }
}

#[instrument]
fn check_direnv() -> Result<(), Report> {
    let shell = env::var("SHELL")?;

    trace!(shell, "checking shell");
    if shell.ends_with("/bash") {
        let direnv_installed =
            match run_fun!(bash --login -c "type -t _direnv_hook || true")?.as_str() {
                "function" => true,
                _ => false,
            };
        trace!(installed = direnv_installed, "checking for direnv");

        if direnv_installed {
            return Ok(());
        } else {
            // XXX FIXME (aseipp): implement direnv installation
            return Err(eyre!("direnv not installed"));
        }
    }

    Err(eyre!("Unsupported shell: {}", shell)
        .wrap_err("This project (and installer) only supports bash (for now)")
        .suggestion("use bash"))
}

#[instrument]
fn check_trusted_users() -> Result<(), Report> {
    let user = env::var("USER")?;
    let trusted = !run_cmd!(nix show-config | grep trusted-users | grep -q "${user}").is_err();

    trace!(trusted, "checking nix trusted-users setting");
    if trusted {
        return Ok(());
    }

    println!(
        "{}Uh oh, you aren't part of the group of Nix 'trusted-users'...",
        Emoji("🚨 ", "")
    );

    // [tag:cache-url-warning] we really need to make a stable URL and
    // public key for the binary cache. one day, but until then, we need to
    // replicate this mindlessly.
    let configured_upstream_cache = run_cmd!(nix show-config | grep "substituters" | grep -q "https://buck2-nix-cache.aseipp.dev").is_ok();
    let has_pubkey_configured = run_cmd!(nix show-config | grep "trusted-public-keys" | grep -q "buck2-nix-preview.aseipp.dev-1:sLpXPuuXpJdk7io25Dr5LrE9CIY1TgGQTPC79gkFj+o=").is_ok();

    if configured_upstream_cache && has_pubkey_configured {
        println!(
            "{}But you have a properly configured upstream cache, so that's okay!",
            Emoji("👍 ", ""),
        );

        let warn = |msg: &str| {
            println!("  {}{}", Emoji("⚠️  ", "-> "), msg,);
        };

        // see [ref:cache-url-warning]; one day we can probably delete this warning when the URL is stable
        warn("Note: your binary cache may stop working if the public key or URL changes in the future.");
        warn("If you are part of the 'trusted-users' group, changes to the public key or URL will be automatically detected.");
        warn("Because you're not part of the 'trusted-users' group, you will need to manually update your configuration.");
        return Ok(());
    }

    // XXX FIXME (aseipp): if there's no substituter or public key, offer to set
    // it up, only if we can 'sudo'. otherwise, fail like we do now.

    Err(eyre!(
        "'{}' is not part of the Nix `trusted-users` setting.",
        user
    ))
    .suggestion("Modify your `nix.conf` file")
}

// -----------------------------------------------------------------------------
// --- Source code management

#[instrument]
fn explain_scm() -> Result<(), Report> {
    let lines = vec![
        format!(""),
        format!("The following tools can be used to clone the source code and manage"),
        format!("the repository. Each has their own advantages and disadvantages."),
        format!(""),
        format!(
            "{}: The following tools are all compatible with the upstream Git\n        repository.",
            style("NOTE").bold().underlined()
        ),
        format!(""),
        format!(
            "{}{} is designed for stacked patch workflows, and ease of use.",
            Emoji("🍃 ", ""),
            style("Sapling").bold().underlined()
        ),
        format!(""),
        format!(
            "       {}: <https://sapling-scm.com>",
            style("Homepage").bold()
        ),
        format!(""),
        format!("   It is Git-compatible, and designed for a stacked patch workflow; it features"),
        format!("   no staging area, a first-class web UI, aggressive support for rebasing, and a"),
        format!("   and easy to use terminal UI for novices or experienced users."),
        format!(""),
        format!(
            "   Sapling is the {} VCS for contributing.",
            style("recommended").bold().underlined()
        ),
        format!(""),
        format!(
            "{}{} is designed to augment the Git data model with new features.",
            Emoji("🥋 ", ""),
            style("Jujutsu").bold().underlined()
        ),
        format!(""),
        format!(
            "       {}: <https://github.com/martinvonz/jj>",
            style("Homepage").bold()
        ),
        format!(""),
        format!("   It combines features like Mercurial revsets, powerful undo and history"),
        format!("   rewriting, first-class conflicts, and no staging area (known as "),
        format!("   \"working-copy-as-a-commit\")"),
        format!(""),
        format!(
            "   Jujutsu is {}, but can be used to contribute.",
            style("experimental").bold().underlined()
        ),
        format!(""),
        format!(
            "{}{} is The Stupid Content Tracker; the classic VCS we know and love.",
            Emoji("👴 ", ""),
            style("Git").bold().underlined()
        ),
        format!(""),
        format!("       {}: <https://git-scm.com>", style("Homepage").bold()),
        format!(""),
        format!("   Git is the most popular VCS in the world, and is used by many projects."),
        format!(
            "   But it is {} for contributing, unless you are an experienced",
            style("not recommended").bold().underlined(),
        ),
        format!(
            "   Git user and know how to use it with {} and {}",
            style("stacked patches").bold(),
            style("rebase-heavy").bold(),
        ),
        format!("   workflows."),
        format!(""),
    ];

    let mut max_len = 0;
    for line in &lines {
        max_len = max_len.max(line.len());
    }

    for line in lines.iter() {
        println!("  {}", line);
    }

    Ok(())
}

#[instrument]
fn choose_scm() -> Result<Scm, Report> {
    let theme = ColorfulTheme::default(); // XXX FIXME (aseipp): propagate

    let choices = vec![
        format!(
            "1) {}Sapling ({})",
            Emoji("🍃 ", ""),
            style("Recommended").bold()
        ),
        format!(
            "2) {}Jujutsu ({})",
            Emoji("🥋 ", ""),
            style("Experimental").bold()
        ),
        format!(
            "3) {}Git     ({})",
            Emoji("👴 ", ""),
            style("Classic").bold()
        ),
        format!("{}What's the difference?", Emoji("❓ ", "?)")),
    ];

    let choice: Result<Scm, Report> = loop {
        match Select::with_theme(&theme)
            .with_prompt("Which source code management tool do you want to use?")
            .default(0)
            .items(&choices[..])
            .interact()?
        {
            0 => break Ok(Scm::Sapling),
            1 => break Ok(Scm::Jujutsu),
            2 => break Ok(Scm::Git),
            3 => {
                explain_scm()?;
                continue;
            }
            _ => unreachable!(),
        }
    };

    choice
}

#[instrument]
fn clone_src(args: &Args, scm: &Scm) -> Result<Option<PathBuf>, Report> {
    let theme = ColorfulTheme::default(); // XXX FIXME (aseipp): propagate

    // [tag:installer-setup-hashes] These hashes were taken from:
    //
    // - nixpkgs-unstable commit bb31220cca6d044baa6dc2715b07497a2a7c4bc7 (2022-12-20)
    // - via `nix-build -A sapling -A jujutsu -A git`
    //
    // XXX FIXME (aseipp): automate this, and make it part of the buck/nix flake somehow?
    let (emoji, storepath) = match scm {
        Scm::Sapling => (
            Emoji("🍃 ", ""),
            "/nix/store/k0xws6hy9mvlqqip5bi5cshqs2bh6sbj-sapling-0.1.20221118-210929-cfbb68aa",
        ),
        Scm::Jujutsu => (
            Emoji("🥋 ", ""),
            "/nix/store/iprb15i0y1gf1v1apiyizanfzz4rywr9-jujutsu-0.6.1",
        ),
        Scm::Git => (
            Emoji("👴 ", ""),
            "/nix/store/cfx715ifm48vanlqdh7f1h3pqjpspbzd-git-2.38.1",
        ),
    };

    let repo_ext = match scm {
        Scm::Sapling => "sl",
        Scm::Jujutsu => "jj",
        Scm::Git => "git",
    };

    let repo_shortname = "buck2-nix"; // XXX FIXME (aseipp): hardcode 'buck2-nix' somewhere else?
    let repo_name = format!("{}.{}", repo_shortname, repo_ext);

    let full_checkout: String = if let Some(checkout_path) = &args.checkout_path {
        String::from(checkout_path)
    } else {
        if args.skip_confirm {
            return Err(
                eyre!("You must specify a checkout path (-c) when using --skip-confirm").into(),
            );
        }
        let path: String = Input::with_theme(&theme)
            .with_prompt("What directory would you like to clone the repository into?")
            .default(env::var("HOME")?.into())
            .interact_text()?;
        let repo: String = Input::with_theme(&theme)
            .with_prompt("What name would you like to use for the cloned checkout?")
            .default(repo_name)
            .interact_text()?;

        let pbuf = PathBuf::from(&path);
        if !pbuf.exists() {
            return Err(eyre!("The path {} does not exist!", path).into());
        }

        let pbuf: PathBuf = pbuf.canonicalize()?.into();

        format!("{}/{}", pbuf.display(), repo)
    };

    let full_checkout_path = PathBuf::from(&full_checkout);
    if full_checkout_path.exists() {
        println!(
            "{}The path `{}` already exists!",
            Emoji("⚠️ ", "ERROR: "),
            full_checkout_path.display(),
        );
        return Ok(None);
    }

    let upstream = &args.upstream;

    let msg = format!(
        r#"I'm going to:

    Clone the repository {}
     into the directory  {}
        using {}{}"#,
        style(upstream).underlined(),
        style(full_checkout_path.display()).underlined(),
        emoji,
        style(scm.to_string()).bold()
    );

    if !args.skip_confirm
        && !Confirm::with_theme(&theme)
            .report(false)
            .with_prompt(format!("{}\n  Do you wish to continue?", msg))
            .interact()?
    {
        return Ok(None);
    }

    if args.skip_confirm {
        println!("{}\n", msg);
    } else {
        println!();
    }

    let tmpdir = env::temp_dir();
    run_cmd!(nix build --out-link "${tmpdir}/${repo_shortname}" "${storepath}")?;
    match scm {
        Scm::Sapling => {
            run_cmd!("${storepath}/bin/sl" clone "${upstream}" "${full_checkout_path}")?;
            run_cmd!("${storepath}/bin/sl" "--kill-chg-daemon")?;
        }
        Scm::Jujutsu => {
            run_cmd!("${storepath}/bin/jj" git clone "${upstream}" "${full_checkout_path}")?;
        }
        Scm::Git => {
            run_cmd!("${storepath}/bin/git" clone "${upstream}" "${full_checkout_path}")?;
        }
    };
    run_cmd!(rm "${tmpdir}/${repo_shortname}")?; // remove gc root

    println!(
        "Successfully cloned {} into {}\n",
        style(upstream).bold(),
        style(full_checkout_path.display()).bold()
    );

    // NOTE: don't automatically allow the '.envrc' without confirmation, to be
    // polite to the user; direnv can be dangerous, after all... and CI can handle
    // this for us anyway. See [ref:direnv-allow-ci] for more details.
    if !args.skip_confirm
        && Confirm::with_theme(&theme)
            .with_prompt(format!(
                r#"May I 'direnv allow' the .envrc file located in '{}'?"#,
                style(full_checkout_path.display()).bold()
            ))
            .interact()?
    {
        run_cmd!(direnv allow "${full_checkout_path}/.envrc")?;
    }

    let watchman = Emoji("👀 ", "");
    if !args.skip_confirm
        && Confirm::with_theme(&theme)
            .report(false)
            .with_prompt(format!(
                r#"Would you like to enable {}Watchman for file tracking?

    Watchman is an efficient daemon for tracking many file changes across a
    large number of directories. The build system, Buck, can integrate directly
    with Watchman to more efficiently track all file changes.

    If you answer 'y' here, then Watchman will be enabled on-demand by creating
    a transient systemd service. It is never installed permanently, and you can
    remove this service at any time and it is not persistent. This is done by
    creating a file named '.use_watchman' at the root of the repository.

    You can undo any choice you make at any time.

    Would you like to enable Watchman for file tracking?"#,
                watchman
            ))
            .interact()?
    {
        run_cmd!(touch "${full_checkout_path}/.use_watchman")?;
        println!("  {}Watchman enabled!\n", watchman);
    } else {
        println!("  {}Watchman not enabled\n", watchman);
    }

    Ok(Some(full_checkout_path))
}

// -----------------------------------------------------------------------------
// Various Impls and utilities

impl Display for Scm {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Scm::Git => write!(f, "Git"),
            Scm::Sapling => write!(f, "Sapling"),
            Scm::Jujutsu => write!(f, "Jujutsu"),
        }
    }
}

impl FromStr for Scm {
    type Err = Report;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s {
            "git" => Ok(Scm::Git),
            "sapling" | "sl" => Ok(Scm::Sapling),
            "jujutsu" | "jj" => Ok(Scm::Jujutsu),
            _ => Err(eyre!("Invalid SCM: {}", s)),
        }
    }
}

fn install_tracing() {
    use tracing_error::ErrorLayer;
    use tracing_subscriber::prelude::*;
    use tracing_subscriber::{fmt, EnvFilter};

    let fmt_layer = fmt::layer().with_target(false);
    let filter_layer = EnvFilter::try_from_default_env()
        .or_else(|_| EnvFilter::try_new("info"))
        .unwrap();

    tracing_subscriber::registry()
        .with(filter_layer)
        .with(fmt_layer)
        .with(ErrorLayer::default())
        .init();
}
