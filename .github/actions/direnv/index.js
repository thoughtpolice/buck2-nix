const core = require('@actions/core');
const cp = require("child_process");

async function run() {
    try {
        // export some variables to help direnv know it's in a CI environment,
        // which may change some minor behavior.
        core.exportVariable('CI_RUNNING', 'true');
        core.exportVariable('CI_RUNNING_SYSTEM', 'github-actions');

        // [tag:direnv-allow-ci] We always allow any directory; this helps us avoid
        // cases where we want to make it 'easy' to run direnv on behalf of the user,
        // like in the installer.
        cp.execSync('direnv allow', { encoding: "utf-8" });
        const envs = JSON.parse(cp.execSync('direnv export json', { encoding: "utf-8" }));

        Object.keys(envs).forEach(function (name) {
            const value = envs[name];
            core.exportVariable(name, value);
        });
    }
    catch (error) {
        core.setFailed(error.message);
    }
}

run()
