# n42translation Tool
Creates locale files for iOS, Android and Rails from common source files.

## Source Files
### Config File

* n42translation-config.yml defines the default outputpaths for Android, iOS and Rails

### Language Files

* <fileprefix>.<lang>.yml (e.g. horsch.en.yml) contains keys for all platforms
* <fileprefix>.<lang>.<target>.yml (e.g. horsch.en.android.yml) contains keys for only this target platform

## Examples

* bundle exec n42translation build android horsch: builds the locales for android from the sources to the default folder given in the config file
* bundle exec n42translation build android horsch myAndroid: builds the locales for android from the sources to the myAndroid folder
* bundle exec n42translation build all horsch: build ios, android and rails to the default folders
* bundle exec n42translation add all horsch "path.to.my_message" "my new message": adds the key path.to.my_message with value "my new message" to the horsch.<lang>.yml files
* bundle exec n42translation add all ios "path.to.my_message" "my new message": adds the key path.to.my_message with value "my new message" to the horsch.<lang>.ios.yml files

