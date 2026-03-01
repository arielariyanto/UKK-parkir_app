const express = require('express');
const cors = require('cors');

const userRoutes = require('./routes/userRoutes');
const registerRoutes = require('./routes/registerRoutes');
const kendaraanRoutes = require('./routes/kendaraanRoutes');
const transaksiRoutes = require('./routes/transaksiRoutes');
const tarifRoutes = require('./routes/tarifRoutes');
const areaRoutes = require('./routes/areaRoutes');
const laporanRoutes = require('./routes/laporanRoutes');

const app = express();

app.use(cors({
    origin: '*',
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization'],
}));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

app.use('/api/user', userRoutes);
app.use('/api/register', registerRoutes);
app.use('/api/kendaraan', kendaraanRoutes);
app.use('/api/transaksi', transaksiRoutes);
app.use('/api/tarif', tarifRoutes);
app.use('/api/area', areaRoutes);
app.use('/api/laporan', laporanRoutes);

module.exports = app;
