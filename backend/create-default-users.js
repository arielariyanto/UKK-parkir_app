const pool = require('./src/config/database');
const bcrypt = require('bcrypt');

async function createDefaultUsers() {
    try {
        console.log('Memeriksa user di database...');

        // Cek apakah sudah ada user
        const [users] = await pool.query('SELECT * FROM tb_user');

        console.log(`Ditemukan ${users.length} user di database:`);
        users.forEach(user => {
            console.log(`- ${user.username} (${user.role}) - Status: ${user.status_aktif ? 'Aktif' : 'Nonaktif'}`);
        });

        // Jika belum ada user admin, buat user default
        const [adminUsers] = await pool.query('SELECT * FROM tb_user WHERE role = "admin"');

        if (adminUsers.length === 0) {
            console.log('\nTidak ada user admin. Membuat user default...');

            const defaultUsers = [
                {
                    nama_lengkap: 'Administrator',
                    username: 'admin',
                    password: 'admin123',
                    role: 'admin'
                },
                {
                    nama_lengkap: 'Petugas 1',
                    username: 'petugas',
                    password: 'petugas123',
                    role: 'petugas'
                },
                {
                    nama_lengkap: 'Owner',
                    username: 'owner',
                    password: 'owner123',
                    role: 'owner'
                }
            ];

            for (const user of defaultUsers) {
                const hashedPassword = await bcrypt.hash(user.password, 10);
                await pool.query(
                    'INSERT INTO tb_user (nama_lengkap, username, password, role, status_aktif) VALUES (?, ?, ?, ?, 1)',
                    [user.nama_lengkap, user.username, hashedPassword, user.role]
                );
                console.log(`✓ User ${user.username} berhasil dibuat (password: ${user.password})`);
            }

            console.log('\n=== USER DEFAULT BERHASIL DIBUAT ===');
            console.log('Username: admin | Password: admin123');
            console.log('Username: petugas | Password: petugas123');
            console.log('Username: owner | Password: owner123');
        } else {
            console.log('\nUser admin sudah ada. Tidak perlu membuat user default.');
            console.log('\n=== KREDENSIAL LOGIN ===');
            console.log('Gunakan username dan password yang sudah ada di database.');
            console.log('Jika lupa password, Anda bisa reset melalui database atau buat user baru.');
        }

        process.exit(0);
    } catch (error) {
        console.error('Error:', error);
        process.exit(1);
    }
}

createDefaultUsers();
