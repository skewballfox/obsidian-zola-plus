from os import environ
from pathlib import Path

import rtoml

if __name__ == "__main__":
    # expanduser() is used to expand the ~ in the path
    # does nothin if ~ is not present
    # absolute() is used to get the absolute path
    env_vars = rtoml.load(
        Path(environ["VAULT"]).expanduser().absolute() / "netlify.toml"
    )["build"]["environment"]
    for k, v in env_vars.items():
        val = v.replace("'", "'\\''")
        print(
            f"export {k}='{val}'",
            file=open("env.sh", "a"),
        )
