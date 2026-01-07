import { emailService } from '../backend/src/services/email.service.js';
import dotenv from 'dotenv';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
dotenv.config({ path: path.join(__dirname, '../backend/.env') });

async function testEmail() {
  console.log('🚀 Starting SMTP test...');
  
  const testRecipient = process.argv[2] || 'noreply@kyte.me';
  
  console.log(`📧 Sending test email to: ${testRecipient}`);
  
  try {
    const result = await emailService.sendEmail(
      testRecipient,
      'Test Email from Kyte Console',
      'If you see this, SMTP is working correctly!',
      '<h1>SMTP Test Success!</h1><p>This message was sent from the command line.</p>'
    );
    
    if (result.success) {
      console.log('✅ Success! Message sent.');
      if (result.mock) {
        console.log('ℹ️ Note: Result was mocked (check service logs if it actually arrived).');
      }
    } else {
      console.error('❌ Failed to send email:', result.error);
    }
  } catch (error) {
    console.error('💥 Unexpected error during test:', error);
  }
}

testEmail();

