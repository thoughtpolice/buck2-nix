const core = require('@actions/core');
const cp = require("child_process");

async function run() {
    try {
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
