# Nginx Reverse Proxy Setup

This setup allows you to easily add subdomains with automatic SSL certificate generation by running a simple script.

## Adding a Subdomain

To add a new subdomain with SSL, run the `add_subdomain.sh` script:

```bash
./add_subdomain.sh <subdomain> <service_name> [port]
```

### Example

```bash
./add_subdomain.sh api.example.com myapi 3000
```

This will:
1. Generate self-signed SSL certificates for `api.example.com` in the `certs/` folder
2. Create a new configuration file `config/conf.d/api.example.com.conf` with both HTTP (redirecting to HTTPS) and HTTPS server blocks that proxy requests to the `myapi` service on port 3000.

### Steps after adding:

1. Add the backend service to your `docker-compose.yml` if not already present.
2. Ensure DNS for the subdomain points to your server.
3. The script automatically restarts nginx to apply changes.

## SSL Certificates

The script automatically generates SSL certificates using `mkcert` for each subdomain. Mkcert creates locally-trusted certificates that work seamlessly with browsers without security warnings.

If you have proper certificates from a CA, you can replace the generated files in the `certs/` folder.

For production use, consider using Let's Encrypt or another CA for valid certificates.

## Existing Services

- `whoami`: Available at `whoami` (internal) or via frontend/whoami