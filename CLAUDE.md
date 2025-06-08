# Project Guidelines

## Testing Policy
- Do not write RSpec tests
- The project may have existing test files but new tests should not be added

## Development Commands
- Check for lint/typecheck commands in package.json or other config files when making changes
- When adding a new JavaScript controller or creating them with `./bin/rails generate stimulus controllerName`, always run `./bin/rails stimulus:manifest:update`