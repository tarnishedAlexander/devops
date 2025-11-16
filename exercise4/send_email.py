#!/usr/bin/env python3

import smtplib
import sys
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from datetime import datetime

def send_email_alert(email_to, email_from, email_password, alert_body):
    """Envía un correo de alerta usando SMTP de Gmail"""
    
    try:
        # Validar que no estén vacíos
        if not email_password or email_password.strip() == "":
            raise ValueError("EMAIL_PASSWORD está vacío. Configúralo en .env")
        
        smtp_server = "smtp.gmail.com"
        smtp_port = 587
        
        message = MIMEMultipart()
        message["From"] = email_from
        message["To"] = email_to
        message["Subject"] = "ALERTA: Recursos del Sistema Excedidos"
        
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        body = f"""
ALERTA DE RECURSOS DEL SISTEMA
==============================

Hora: {timestamp}

{alert_body}

Por favor, revisa el estado del sistema.

---
Generado automáticamente por monitor_system.sh
"""
        
        message.attach(MIMEText(body, "plain"))
        
        print(f"📧 Conectando a SMTP de Gmail...", file=sys.stderr)
        with smtplib.SMTP(smtp_server, smtp_port) as server:
            server.starttls()
            print(f"🔐 Autenticando...", file=sys.stderr)
            server.login(email_from, email_password)
            print(f"📤 Enviando mensaje a {email_to}...", file=sys.stderr)
            server.send_message(message)
        
        print(f"✓ Correo enviado exitosamente a {email_to}", file=sys.stderr)
        return True
    
    except smtplib.SMTPAuthenticationError as e:
        print(f"❌ Error de autenticación: Verifica EMAIL_FROM y EMAIL_PASSWORD en .env", file=sys.stderr)
        print(f"   Detalles: {str(e)}", file=sys.stderr)
        return False
    except smtplib.SMTPException as e:
        print(f"❌ Error SMTP: {str(e)}", file=sys.stderr)
        return False
    except Exception as e:
        print(f"❌ Error al enviar correo: {str(e)}", file=sys.stderr)
        return False

if __name__ == "__main__":
    if len(sys.argv) < 4:
        print("Uso: python3 send_email.py <email_to> <email_from> <email_password>", file=sys.stderr)
        sys.exit(1)
    
    email_to = sys.argv[1]
    email_from = sys.argv[2]
    email_password = sys.argv[3]
    alert_body = sys.stdin.read()
    
    if send_email_alert(email_to, email_from, email_password, alert_body):
        sys.exit(0)
    else:
        sys.exit(1)
