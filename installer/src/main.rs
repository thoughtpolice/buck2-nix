//! An 'setup installer' for the project and build system. This largely just
//! automates installation of 'direnv' as well as using Sapling to clone the
//! repository, and warning the user of some gotchas.

// -----------------------------------------------------------------------------

#![deny(missing_docs)]
#![allow(unused_imports)]

use std::path::Path;
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

// -----------------------------------------------------------------------------

fn main() -> Result<(), Report> {
    install_tracing();
    color_eyre::install()?;

    let term = Term::stdout();
    term.clear_screen()?;

    trace!("Starting setup installer");

    let theme = ColorfulTheme::default(); // XXX FIXME (aseipp): propagate
    if !Confirm::with_theme(&theme)
        .report(false)
        .with_prompt(format!(
            r#"This is the setup and installer for the project and build system.

  This installer tool largely automates installation of 'direnv' as well as
  using your chosen source code management tool to clone the repository, and
  warning the user of some gotchas.

  This is a work in progress, and may have bugs.

  You can quit at any time with {}

  Do you wish to continue?
"#,
            style("Ctrl-C").underlined()
        ))
        .interact()?
    {
        println!("\nOK, bye!");
        return Ok(());
    }

    check_prereqs()?;
    check_direnv()?;
    check_trusted_users()?;

    let scm = choose_scm()?;
    clone_src("https://github.com/thoughtpolice/buck2-nix", &scm)
}

// -----------------------------------------------------------------------------

const MSNV: &str = "2.12.0";

#[instrument]
fn check_prereqs() -> Result<(), Report> {
    let (os, supported) = if cfg!(target_os = "linux") {
        ("Linux", true)
    } else if cfg!(target_os = "macos") {
        ("macOS", false /* XXX FIXME (aseipp): macOS support */)
    } else if cfg!(target_os = "windows") {
        ("Windows", false)
    } else {
        ("Unknown", false)
    };

    info!(os, supported, "checking operating system");
    if !supported {
        return Err(eyre!("Unsupported operating system: {}", os)
            .wrap_err("This project (and installer) only supports Linux (for now)")
            .suggestion("use a Linux distribution"));
    }

    let n = run_fun!(nix eval --raw --expr "builtins.nixVersion")?;
    let v = run_fun!(nix eval --expr "builtins.compareVersions \"${n}\" \"${MSNV}\"")?;
    info!(
        msnv = MSNV,
        nixver = n,
        result = v,
        "checking nix compatbility",
    );

    match v.as_str() {
        "-1" => {
            return Err(eyre!("Incompatible Nix version: {}", n)
                .wrap_err(format!("Version {} is too old", n))
                .suggestion(format!("upgrade Nix to {} or later", MSNV)))
        }
        _ => {}
    };

    Ok(())
}

#[instrument]
fn check_direnv() -> Result<(), Report> {
    let shell = env!("SHELL");

    info!(shell, "checking shell");
    if shell.ends_with("/bash") {
        let direnv_installed =
            match run_fun!(bash --login -c "type -t _direnv_hook || true")?.as_str() {
                "function" => true,
                _ => false,
            };
        info!(installed = direnv_installed, "checking for direnv");

        if direnv_installed {
            return Ok(());
        } else {
            // XXX FIXME (aseipp): implement
            return Err(eyre!("direnv not installed"));
        }
    }

    Err(eyre!("Unsupported shell: {}", shell)
        .wrap_err("This project (and installer) only supports bash (for now)")
        .suggestion("use bash"))
}

#[instrument]
fn check_trusted_users() -> Result<(), Report> {
    let user = env!("USER");
    let trusted = !run_cmd!(nix show-config | grep trusted-users | grep -q "${user}").is_err();

    info!(trusted, "checking nix trusted-users setting");
    if trusted {
        return Ok(());
    }

    Err(eyre!(
        "'{}' is not part of the Nix `trusted-users` setting.",
        user
    ))
    .suggestion("Modify your `nix.conf` file")
}

// -----------------------------------------------------------------------------

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
enum Scm {
    Git,
    Sapling,
    Jujutsu,
}

impl Display for Scm {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Scm::Git => write!(f, "Git"),
            Scm::Sapling => write!(f, "Sapling"),
            Scm::Jujutsu => write!(f, "Jujutsu"),
        }
    }
}

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
            "{}{}Sapling ({})",
            Emoji("1️⃣  ", "1) "),
            Emoji("🍃 ", ""),
            style("Recommended").bold()
        ),
        format!(
            "{}{}Jujutsu ({})",
            Emoji("2️⃣  ", "2) "),
            Emoji("🥋 ", ""),
            style("Experimental").bold()
        ),
        format!(
            "{}{}Git     ({})",
            Emoji("3️⃣  ", "3) "),
            Emoji("👴 ", ""),
            style("Classic").bold()
        ),
        format!("{}What's the difference?", Emoji("❓ ", "?)")),
    ];

    let choice: Result<(usize, Scm), Report> = loop {
        match Select::with_theme(&theme)
            .with_prompt("Which source code management tool do you want to use?")
            .default(0)
            .items(&choices[..])
            .interact()?
        {
            0 => break Ok((0, Scm::Sapling)),
            1 => break Ok((1, Scm::Jujutsu)),
            2 => break Ok((2, Scm::Git)),
            3 => {
                explain_scm()?;
                continue;
            }
            _ => unreachable!(),
        }
    };
    let (_, scm) = choice?;

    let suggestion = "Please choose Sapling";
    match scm {
        Scm::Sapling => Ok(scm),
        _ => Err(eyre!("{} is not supported yet", scm)).suggestion(suggestion),
    }
}

#[instrument]
fn clone_src(reponame: &str, vcs: &Scm) -> Result<(), Report> {
    let theme = ColorfulTheme::default(); // XXX FIXME (aseipp): propagate

    let (emoji, storepath) = match vcs {
        Scm::Sapling => (
            Emoji("🍃 ", ""),
            "/nix/store/8gazwcbkhb09qcshxyf90s5ixa9h7635-sapling-0.1.20221118-210929-cfbb68aa",
        ),
        Scm::Jujutsu => (Emoji("🥋 ", ""), "FIXME"),
        Scm::Git => (Emoji("👴 ", ""), "FIXME"),
    };

    let upstream = "https://github.com/thoughtpolice/buck2-nix"; // XXX FIXME (aseipp): hardcode somewhere else?
    let path: String = Input::with_theme(&theme)
        .with_prompt("What directory would you like to clone the repository into?")
        .default(env!("HOME").into())
        .interact_text()?;

    let repo: String = Input::with_theme(&theme)
        .with_prompt("What name would you like to use for the cloned checkout?")
        .default("buck2-nix.sl".into()) // XXX FIXME (aseipp): hardcode somewhere else?
        .interact_text()?;

    let full_checkout = format!("{}/{}", path, repo);
    let full_checkout_path = Path::new(full_checkout.as_str());

    if full_checkout_path.exists() {
        println!(
            "The path {} already exists! Skipping",
            full_checkout_path.display(),
        );
        return Ok(());
    }

    if !Confirm::with_theme(&theme)
        .report(false)
        .with_prompt(format!(
            r#"I'm going to:
            
    Clone the repository {}
     into the directory  {}
        using {}{}

  Do you wish to continue?
"#,
            style(upstream).underlined(),
            style(full_checkout_path.display()).underlined(),
            emoji,
            style(vcs.to_string()).bold()
        ))
        .interact()?
    {
        return Ok(());
    }

    let suggestion = "Please choose Sapling";
    match vcs {
        Scm::Sapling => {
            run_cmd!(nix build "${storepath}")?;
            run_cmd!("${storepath}/bin/sl" clone "${upstream}" "${full_checkout_path}")?;
            run_cmd!("${storepath}/bin/sl" "--kill-chg-daemon")?;

            println!(
                "Successfully cloned {} into {}\n",
                style(upstream).bold(),
                style(full_checkout_path.display()).bold()
            );

            if !Confirm::with_theme(&theme)
                .with_prompt(format!(
                    r#"May I 'direnv allow' the .envrc file located in '{}'?"#,
                    style(full_checkout_path.display()).bold()
                ))
                .interact()?
            {
                run_cmd!(direnv allow "${full_checkout_path}/.envrc")?;
            }

            println!(
                r#"{}{} {}

  You can now 'cd' into '{}' and begin developing!
  
  Upon doing so, {} will activate, populating your shell with the needed environment.
"#,
                Emoji("✔ ", "").green(),
                style("Finished!").bold(),
                Emoji("🎉 🎉 🎉", ""),
                style(full_checkout_path.display()).bold(),
                style("direnv").bold()
            );

            Ok(())
        }
        _ => Err(eyre!("{} is not supported yet", vcs)).suggestion(suggestion),
    }
}

// -----------------------------------------------------------------------------

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
