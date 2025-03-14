# browser_extension

## Building

First of all, run:
```bash
flutter pub get
```

This will also regenerate translations.

To build the extension, run the following command:

```bash
flutter build web --no-web-resources-cdn
```

- `--no-web-resources-cdn` is used to load libraries (specifically canvaskit) locally rather than through a CDN.


## Firefox setup

1. In search bar type `about:debugging`
2. Press `Load Temporary Add-on`
3. Go to select `<extendion_dir>/build/web/manifest.json`

## Chrome setup

1. In search bar type `chrome:extensions`
2. Enable *Developer mode*
3. Press `Load unpacked`
4. Select the web directory `<extension_dirt>/build/web`


## predefined.json

This file contains predefined list of websites, their forms and fields with generators.

```json
{
   // Hostname, subdomains will not match
   "github.com": {
      // Declare a list of forms
      "forms": [
         {
            // Unused for now, represents the purpose of the form
            "purpose": "Login",
            // How this form is matched, currently supports single type="static"
            // Which checks the current URL against the Regex pattern
            "match": {
               "type": "static",
               "pattern": "github\\.com/login"
            },
            // Fields that should be detected and their value generator namespace
            "fields": [
               {
                  // CSS selector that calls querySelector underneath
                  "selector": "input[id='password']",
                  // Generator namespace
                  "generator": "namespace::password_generator"
               },
               {
                  "selector": "input[id='login_field']",
                  "generator": "namespace::username_generator"
               }
            ]
         },
         {
            "purpose": "Register",
            "match": {
               "type": "static",
               "pattern": "github\\.com/signup"
            },
            "fields": [
               {
                  "selector": "input[id='email']",
                  "generator": "namespace::email_generator"
               },
               {
                  "selector": "input[id='password']",
                  "generator": "namespace::password_generator"
               },
               {
                  "selector": "input[id='login']",
                  "generator": "namespace::username_generator"
               }
            ]
         }
      ]
   }
}
```