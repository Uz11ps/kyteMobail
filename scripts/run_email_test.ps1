
$ServerIP = "94.131.88.135"
$User = "kyte-777"
$Key = "C:\Users\1\.ssh\yandex_key\ssh-key-1765132631789"

Write-Host "🚀 Uploading test script..." -ForegroundColor Yellow
scp -i $Key -o StrictHostKeyChecking=no scripts/test_email_curl.sh "$User@$ServerIP:/home/$User/test_email_curl.sh"

Write-Host "🚀 Running test on server..." -ForegroundColor Yellow
ssh -i $Key -o StrictHostKeyChecking=no "$User@$ServerIP" "chmod +x /home/$User/test_email_curl.sh && /home/$User/test_email_curl.sh"

Write-Host ""
Write-Host "📋 Checking logs for the generated code..." -ForegroundColor Yellow
ssh -i $Key -o StrictHostKeyChecking=no "$User@$ServerIP" "grep -r 'GENERATED EMAIL CODE' /home/$User/.pm2/logs/kyte-backend-out.log | tail -n 5"


