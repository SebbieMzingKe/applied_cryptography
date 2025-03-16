#!/bin/bash

# Script to demonstrate GnuPG (5b) and S/MIME (5a) setup

echo "=== Starting Cryptography Demo ==="

# --- 5b: Secure Data Storage, Transmission, and Digital Signatures with GnuPG ---

echo "=== 5b: GnuPG Setup ==="

# Step 1: Generate a GPG Key Pair
echo "Generating a GPG key pair (this is interactive)..."
gpg --full-generate-key
echo "Key generation complete. Check your keys:"
gpg --list-keys

# Prompt for user's email (to match the generated key)
read -p "Enter your email address used for the GPG key (e.g., spacex@gmail.com): " MY_EMAIL

# Step 2: Secure Data Storage
echo "=== Step 2: Secure Data Storage ==="
echo "Creating a sample file 'secret.txt'..."
echo "This is secret data" > secret.txt

echo "Encrypting 'secret.txt' for $MY_EMAIL..."
gpg -e -r "$MY_EMAIL" secret.txt
if [ -f "secret.txt.gpg" ]; then
    echo "Encryption successful. Verifying encrypted file (should be unreadable):"
    cat secret.txt.gpg
else
    echo "Error: Encryption failed!"
    exit 1
fi

echo "Decrypting 'secret.txt.gpg' to 'secret_decrypted.txt'..."
gpg -d secret.txt.gpg > secret_decrypted.txt
if [ -f "secret_decrypted.txt" ]; then
    echo "Decryption successful. Contents of decrypted file:"
    cat secret_decrypted.txt
else
    echo "Error: Decryption failed!"
    exit 1
fi

# Step 3: Secure Data Transmission
echo "=== Step 3: Secure Data Transmission ==="
echo "Exporting your public key to 'mypubkey.asc'..."
gpg --armor --export "$MY_EMAIL" > mypubkey.asc
if [ -f "mypubkey.asc" ]; then
    echo "Public key exported. Contents:"
    cat mypubkey.asc
else
    echo "Error: Export failed!"
    exit 1
fi

# Prompt for friend's public key file
read -p "Enter the path to your friend's public key file (e.g., fpubkkey.asc): " FRIEND_KEY
read -p "Enter your friend's email address (e.g., friend@gmail.com): " FRIEND_EMAIL

echo "Importing friend's public key from $FRIEND_KEY..."
gpg --import "$FRIEND_KEY"
echo "Imported keys:"
gpg --list-keys "$FRIEND_EMAIL"

echo "Encrypting 'secret.txt' for $FRIEND_EMAIL..."
gpg -e -r "$FRIEND_EMAIL" secret.txt
if [ -f "secret.txt.gpg" ]; then
    echo "Encryption for transmission successful. 'secret.txt.gpg' is ready to send."
else
    echo "Error: Encryption for friend failed!"
    exit 1
fi

# Step 4: Create and Verify Digital Signatures
echo "=== Step 4: Digital Signatures ==="
echo "Signing 'secret.txt'..."
gpg --sign secret.txt
if [ -f "secret.txt.gpg" ]; then
    echo "Signature created. Verifying 'secret.txt.gpg'..."
    gpg --verify secret.txt.gpg
else
    echo "Error: Signing failed!"
    exit 1
fi

# --- 5a: Configuring S/MIME for Email Communication ---

echo "=== 5a: S/MIME Setup ==="

# Step 1: Generate Private Key
echo "Generating RSA private key 'email_key.pem'..."
openssl genrsa -out email_key.pem 2048
if [ -f "email_key.pem" ]; then
    echo "Private key generated."
else
    echo "Error: Private key generation failed!"
    exit 1
fi

# Step 2: Generate Certificate Signing Request (CSR)
echo "Generating CSR 'email.csr' (this is interactive)..."
openssl req -new -key email_key.pem -out email.csr

# Step 3: Generate Self-Signed Certificate and Combine into PKCS12
echo "Generating self-signed certificate 'email_cert.pem'..."
openssl x509 -req -days 365 -in email.csr -signkey email_key.pem -out email_cert.pem
if [ -f "email_cert.pem" ]; then
    echo "Self-signed certificate generated."
else
    echo "Error: Certificate generation failed!"
    exit 1
fi

echo "Combining key and certificate into 'email_cert.p12' (set a password when prompted)..."
openssl pkcs12 -export -in email_cert.pem -inkey email_key.pem -out email_cert.p12
if [ -f "email_cert.p12" ]; then
    echo "PKCS12 file created. Ready for email client import."
else
    echo "Error: PKCS12 creation failed!"
    exit 1
fi

echo "=== Demo Complete! ==="
echo "Files generated:"
ls -lh secret.txt secret.txt.gpg secret_decrypted.txt mypubkey.asc email_key.pem email.csr email_cert.pem email_cert.p12
