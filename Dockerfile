# Use the official PHP Apache image
FROM php:8.2-apache

# Copy PHP source files to the container's web root
COPY src/ /var/www/html/

# Set permissions (optional but recommended)
RUN chown -R www-data:www-data /var/www/html
