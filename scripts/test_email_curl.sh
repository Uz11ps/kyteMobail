#!/bin/bash
echo "📧 Sending test request to backend..."
curl -v -X POST http://localhost:3000/api/auth/email/send-code \
  -H "Content-Type: application/json" \
  -d '{"email":"vvedenskiy.2020@mail.ru"}'
echo ""
echo "✅ Request sent."


