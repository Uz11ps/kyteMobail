
# Script to update SMTP settings on the server
$serverIp = "94.131.88.135"
$sshUser = "kyte-777"
$sshKeyPath = "C:\Users\1\.ssh\yandex_key\ssh-key-1765132631789"

$smtpHost = "smtp.elasticemail.com"
$smtpPort = "2525"
$smtpUser = "noreply@kyte.me"
$smtpPass = "ADA0DD9EBFC3A2169F452EDC4BD77011239C"
$smtpFrom = "Kyte"

# Commands to run on server
$commands = @(
    "cd /var/www/kyte-backend/backend",
    "sed -i '/SMTP_HOST/d' .env",
    "sed -i '/SMTP_PORT/d' .env",
    "sed -i '/SMTP_USER/d' .env",
    "sed -i '/SMTP_PASS/d' .env",
    "sed -i '/SMTP_FROM_NAME/d' .env",
    "echo 'SMTP_HOST=$smtpHost' >> .env",
    "echo 'SMTP_PORT=$smtpPort' >> .env",
    "echo 'SMTP_USER=$smtpUser' >> .env",
    "echo 'SMTP_PASS=$smtpPass' >> .env",
    "echo 'SMTP_FROM_NAME=$smtpFrom' >> .env",
    "pm2 restart kyte-backend",
    "echo '✅ SMTP settings updated and server restarted'"
)

$remoteCommand = $commands -join " && "

Write-Host "🔌 Connecting to $serverIp..."
ssh -i $sshKeyPath -o StrictHostKeyChecking=no $sshUser@$serverIp $remoteCommand

