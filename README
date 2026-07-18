# Server Rules WP (Luanti Mod)

[![Luanti](https://img.shields.io/badge/Luanti-5.0+-blue.svg)](https://www.luanti.org/)

A Luanti (formerly Minetest) mod that dynamically fetches and displays server rules from a WordPress site using the WordPress REST API. 

## How it Works
The mod connects to a specified WordPress page via HTTP, parses the raw HTML content, and translates it into a clean, easy-to-read in-game `hypertext` window. 

## Installation

1. Clone this repository into your Luanti `mods/` directory. Ensure the folder is named `server_rules_wp`:
   ```bash
   cd ~/.minetest/mods/
   git clone https://github.com/jjk4/luanti_server_rules_wp.git server_rules_wp
   ```
2. Enable the mod in your `world.mt` file or via the Luanti main menu.

## Configuration

The mod requires explicit configuration to work. **There are no default fallback values.** Add the following lines to your `minetest.conf`:

### 1. Grant Internet Permissions
The mod needs authorization to fetch data from your website. Add `server_rules_wp` to your trusted HTTP mods list:
```ini
secure.http_mods = server_rules_wp
```
*(Note: If you already have other mods using the HTTP API, separate them with a comma, e.g., `secure.http_mods = mapserver, server_rules_wp`)*

### 2. Set the WordPress URL
Specify the REST API endpoint of your WordPress page. You need to know the ID of the page containing your rules (e.g., `161`).
```ini
server_rules_wp_url = https://jojokorpi.ddns.net/mt-servers-by-walker/index.php/wp-json/wp/v2/pages/161
```
*(You can also configure this URL directly inside the Luanti main menu via Settings -> Advanced Settings -> Mods -> server_rules_wp).*

## Commands

* `/rules` - Opens the graphical interface displaying the server rules. *(Available to everyone)*
* `/refresh_rules` - Reloads the rules from the WordPress page in the background. *(Requires the `server` privilege)*

## Troubleshooting
* **"Error: Mod lacks internet permission"**: Double-check your `secure.http_mods` setting in `minetest.conf`.
* **"Error: No URL configured"**: Ensure `server_rules_wp_url` is properly set and has no typos.
* **Text looks messy or tags are visible**: Ensure your WordPress page uses standard block elements. The mod automatically filters most complex HTML, but plain `<p>`, `<h1>` to `<h4>`, `<ul>`, and `<li>` work best.