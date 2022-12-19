//! An 'setup installer' for the project and build system. This largely just
//! automates installation of 'direnv' as well as using Sapling to clone the
//! repository, and warning the user of some gotchas.

// -----------------------------------------------------------------------------

#![deny(missing_docs)]

use std::thread;
use std::time::Duration;

use color_eyre::{Help, Report};
use eyre::{Context, Result};
use tracing::{info, instrument};

use console::Term;
use dialoguer::theme::ColorfulTheme;
use indicatif::ProgressIterator;

// -----------------------------------------------------------------------------

fn main() -> Result<(), Report> {
    install_tracing();
    color_eyre::install()?;

    let term = Term::stdout();
    let _theme = ColorfulTheme::default();

    term.write_line("Hello World!")?;

    for _ in (0..100).progress() {
        // do something
        thread::sleep(Duration::from_millis(20));
    }

    read_config()?;
    Ok(())
}

// -----------------------------------------------------------------------------

#[instrument]
fn read_file(path: &str) -> Result<(), Report> {
    info!("Reading file");
    Ok(std::fs::read_to_string(path).map(drop)?)
}

#[instrument]
fn read_config() -> Result<(), Report> {
    read_file("fake_file")
        .wrap_err("Unable to read config")
        .suggestion("try using a file that exists next time")
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
