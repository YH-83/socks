#!/bin/bash

# سكربت Bash لتثبيت وإعداد خادم SOCKS مع مصادقة اسم المستخدم وكلمة المرور باستخدام Dante

echo "تثبيت خادم Dante..."
sudo apt install dante-server -y

echo "إعداد ملف التكوين الخاص بخادم Dante..."
# نسخ ملف التكوين الافتراضي كنسخة احتياطية
sudo cp /etc/danted.conf /etc/danted.conf.bak

# كتابة ملف تكوين جديد مع مصادقة اسم المستخدم وكلمة المرور
sudo bash -c 'cat > /etc/danted.conf' <<EOF
logoutput: syslog
internal: eth0 port = 1080
external: eth0
method: username
user.privileged: root
user.notprivileged: nobody
client pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
    log: error
}
socks pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
    log: error
}
EOF

echo "إنشاء ملف قاعدة بيانات المستخدمين..."
sudo touch /etc/sockd.passwd
sudo chmod 600 /etc/sockd.passwd

echo "إضافة مستخدم جديد..."
read -p "أدخل اسم المستخدم: " username
read -sp "أدخل كلمة المرور: " password
echo
sudo bash -c "echo '$username:$password' >> /etc/sockd.passwd"

echo "إعداد PAM لدعم المصادقة..."
# تثبيت وحدة PAM إذا لم تكن موجودة
sudo apt install libpam-pwdfile -y
# إنشاء ملف PAM الخاص بخادم Dante
sudo bash -c 'cat > /etc/pam.d/sockd' <<EOF
auth required pam_pwdfile.so pwdfile=/etc/sockd.passwd
account required pam_permit.so
EOF

echo "إعادة تشغيل خدمة Dante..."
sudo systemctl restart danted

echo "تم تثبيت وإعداد خادم SOCKS مع المصادقة بنجاح!"
echo "يمكنك الآن الاتصال عبر العنوان: $(hostname -I | awk '{print $1}'):1080"
