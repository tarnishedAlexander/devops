#!/usr/bin/env python3

import smtplib
import sys
import os
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from datetime import datetime

def send_email_alert(service_name, email_to, email_from, email_password):
    """Envía un correo de alerta usando SMTP de Gmail"""
    
    try:
        # Configurar servidor SMTP de Gmail
        smtp_server = "smtp.gmail.com"
        smtp_port = 587
        
        # Crear el mensaje
        message = MIMEMultipart()
        message["From"] = email_from
        message["To"] = email_to
        message["Subject"] = f"ALERTA: Servicio '{service_name}' está inactivo"
        
        # Cuerpo del mensaje
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        body = f"""
ALERTA DE SERVICIO INACTIVO
===========================

Servicio: {service_name}
Estado: INACTIVO
Hora: {timestamp}

Por favor, revisa el estado del servicio inmediatamente.

---
Este mensaje fue generado automáticamente por check_service.sh
"""
        
        message.attach(MIMEText(body, "plain"))
        
        # Conectar y enviar
        with smtplib.SMTP(smtp_server, smtp_port) as server:
            server.starttls()  # Iniciar TLS
            server.login(email_from, email_password)
            server.send_message(message)
        
        return True, "Correo enviado exitosamente"
    
    except smtplib.SMTPAuthenticationError:
        return False, "Error de autenticación. Verifica EMAIL_FROM y EMAIL_PASSWORD"
    except smtplib.SMTPException as e:
        return False, f"Error SMTP: {str(e)}"
    except Exception as e:
        return False, f"Error al enviar correo: {str(e)}"

if __name__ == "__main__":
    if len(sys.argv) < 4:
        print("Uso: python3 send_email.py <servicio> <email_to> <email_from> <email_password>")
        sys.exit(1)
    
    service = sys.argv[1]
    email_to = sys.argv[2]
    email_from = sys.argv[3]
    email_password = sys.argv[4]
    
    success, message = send_email_alert(service, email_to, email_from, email_password)
    
    if success:
        print(f"✓ {message}")
        sys.exit(0)
    else:
        print(f"✗ {message}")
        sys.exit(1)
