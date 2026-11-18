const fs = require('fs');

// 1. Fix home_screen.dart
{
  const filePath = 'lib/features/masyarakat/home/presentation/screens/home_screen.dart';
  let c = fs.readFileSync(filePath, 'utf8');

  // Fix Aksi Cepat horizontal padding from 24 to 16
  c = c.replace(
    'padding: const EdgeInsets.symmetric(horizontal: 24),\n                  child: Row(\n                    mainAxisAlignment: MainAxisAlignment.spaceBetween,\n                    children: [\n                      Expanded(\n                        child: QuickActionItem(\n                          icon: Icons.camera_alt_rounded,\n                        label: \'Lapor\\nSekarang\',',
    'padding: const EdgeInsets.symmetric(horizontal: 16),\n                  child: Row(\n                    mainAxisAlignment: MainAxisAlignment.spaceBetween,\n                    crossAxisAlignment: CrossAxisAlignment.start,\n                    children: [\n                      Expanded(\n                        child: QuickActionItem(\n                          icon: Icons.camera_alt_rounded,\n                          label: \'Lapor\\nSekarang\','
  );

  // Fix SizedBox width from 12 to 8 in Aksi Cepat
  c = c.replaceAll('const SizedBox(width: 12),\n                      Expanded(\n                        child: QuickActionItem', 'const SizedBox(width: 8),\n                      Expanded(\n                        child: QuickActionItem');

  // Fix Laporan Terbaru Saya header
  c = c.replace(
    'const Column(\n                            crossAxisAlignment: CrossAxisAlignment.start,\n                            children: [\n                              Text(\n                                \'Laporan Terbaru Saya\',',
    'const Expanded(\n                            child: Column(\n                              crossAxisAlignment: CrossAxisAlignment.start,\n                              children: [\n                                Text(\n                                  \'Laporan Terbaru Saya\','
  );
  c = c.replace(
    'style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),\n                            ],\n                          ),\n                          TextButton(\n                            onPressed: () => _openMyLaporan(\'semua\'),',
    'style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),\n                              ],\n                            ),\n                          ),\n                          const SizedBox(width: 8),\n                          TextButton(\n                            onPressed: () => _openMyLaporan(\'semua\'),'
  );

  // Fix Laporan di Sekitar header
  c = c.replace(
    'Column(\n                              crossAxisAlignment: CrossAxisAlignment.start,\n                              children: [\n                                const Text(\'Laporan di Sekitar\',\n                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),\n                                const SizedBox(height: 4),\n                                Text(\n                                  _userLat != null ? \'Radius 5 km dari lokasi Anda\' : \'Aktifkan GPS untuk filter lokasi\',\n                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),\n                                ),\n                              ],\n                            ),\n                            TextButton(\n                              onPressed: _openPeta,',
    'Expanded(\n                              child: Column(\n                                crossAxisAlignment: CrossAxisAlignment.start,\n                                children: [\n                                  const Text(\'Laporan di Sekitar\',\n                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),\n                                  const SizedBox(height: 4),\n                                  Text(\n                                    _userLat != null ? \'Radius 5 km dari lokasi Anda\' : \'Aktifkan GPS untuk filter lokasi\',\n                                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),\n                                    maxLines: 1,\n                                    overflow: TextOverflow.ellipsis,\n                                  ),\n                                ],\n                              ),\n                            ),\n                            const SizedBox(width: 8),\n                            TextButton(\n                              onPressed: _openPeta,'
  );

  // Increase nearby reports card height from 170 to 184
  c = c.replace('height: 170,', 'height: 184,');

  // Increase bottom spacer so BottomAppBar does not cover content
  c = c.replace('const SizedBox(height: 40),', 'const SizedBox(height: 80),');

  fs.writeFileSync(filePath, c, 'utf8');
  console.log('home_screen.dart patched successfully');
}

// 2. Fix home_widgets.dart
{
  const filePath = 'lib/features/masyarakat/home/presentation/widgets/home_widgets.dart';
  let c = fs.readFileSync(filePath, 'utf8');

  // QuickActionItem container size from 60 to 54 to prevent narrow-screen overflow
  c = c.replace(
    'Container(\n            width: 60,\n            height: 60,',
    'Container(\n            width: 54,\n            height: 54,'
  );

  // HomeHeader greeting text add maxLines & overflow
  c = c.replace(
    'Text(\n                  \'Halo, $_displayName! 👋\',\n                  style: const TextStyle(\n                    fontSize: 20,\n                    fontWeight: FontWeight.bold,\n                    color: Colors.white,\n                  ),\n                ),',
    'Text(\n                  \'Halo, $_displayName! 👋\',\n                  maxLines: 1,\n                  overflow: TextOverflow.ellipsis,\n                  style: const TextStyle(\n                    fontSize: 20,\n                    fontWeight: FontWeight.bold,\n                    color: Colors.white,\n                  ),\n                ),'
  );

  // HomeHeader date text wrap in Expanded
  c = c.replace(
    'const SizedBox(width: 8),\n                    Text(\n                      \'Kab. Jember • ${_getRealtimeDate()}\',\n                      style: TextStyle(\n                        fontSize: 12,\n                        color: Colors.white.withValues(alpha: 0.8),\n                      ),\n                    ),',
    'const SizedBox(width: 8),\n                    Expanded(\n                      child: Text(\n                        \'Kab. Jember • ${_getRealtimeDate()}\',\n                        maxLines: 1,\n                        overflow: TextOverflow.ellipsis,\n                        style: TextStyle(\n                          fontSize: 12,\n                          color: Colors.white.withValues(alpha: 0.8),\n                        ),\n                      ),\n                    ),'
  );

  // RecentReportTile status and date row overflow fix
  c = c.replace(
    'Row(\n                    mainAxisAlignment: MainAxisAlignment.spaceBetween,\n                    children: [\n                      Container(\n                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),\n                        decoration: BoxDecoration(\n                          color: statusBgColor,\n                          borderRadius: BorderRadius.circular(8),\n                        ),\n                        child: Row(\n                          children: [\n                            Container(\n                              width: 6,\n                              height: 6,\n                              decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),\n                            ),\n                            const SizedBox(width: 4),\n                            Text(\n                              status,\n                              style: TextStyle(\n                                color: statusColor,\n                                fontSize: 10,\n                                fontWeight: FontWeight.bold,\n                              ),\n                              maxLines: 1,\n                              overflow: TextOverflow.ellipsis,\n                            ),\n                          ],\n                        ),',
    'Row(\n                    mainAxisAlignment: MainAxisAlignment.spaceBetween,\n                    children: [\n                      Flexible(\n                        child: Container(\n                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),\n                          decoration: BoxDecoration(\n                            color: statusBgColor,\n                            borderRadius: BorderRadius.circular(8),\n                          ),\n                          child: Row(\n                            mainAxisSize: MainAxisSize.min,\n                            children: [\n                              Container(\n                                width: 6,\n                                height: 6,\n                                decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),\n                              ),\n                              const SizedBox(width: 4),\n                              Flexible(\n                                child: Text(\n                                  status,\n                                  style: TextStyle(\n                                    color: statusColor,\n                                    fontSize: 10,\n                                    fontWeight: FontWeight.bold,\n                                  ),\n                                  maxLines: 1,\n                                  overflow: TextOverflow.ellipsis,\n                                ),\n                              ),\n                            ],\n                          ),\n                        ),\n                      ),\n                      const SizedBox(width: 8),'
  );

  fs.writeFileSync(filePath, c, 'utf8');
  console.log('home_widgets.dart patched successfully');
}

// 3. Fix my_laporan_page.dart
{
  const filePath = 'lib/features/masyarakat/presentation/pages/laporan/list/my_laporan_page.dart';
  let c = fs.readFileSync(filePath, 'utf8');

  // Report card header: wrap nomor in Flexible and status in Flexible
  c = c.replace(
    '// 1. Header: Nomor Laporan & Status Badge\n                Row(\n                  children: [\n                    Container(\n                      padding: const EdgeInsets.symmetric(\n                        horizontal: 8,\n                        vertical: 3,\n                      ),\n                      decoration: BoxDecoration(\n                        color: const Color(0xFFF1F5F9),\n                        borderRadius: BorderRadius.circular(6),\n                      ),\n                      child: Row(\n                        mainAxisSize: MainAxisSize.min,\n                        children: [\n                          const Icon(\n                            Icons.tag_rounded,\n                            size: 13,\n                            color: Color(0xFF64748B),\n                          ),\n                          const SizedBox(width: 2),\n                          Text(\n                            nomor,\n                            style: const TextStyle(\n                              fontSize: 11,\n                              fontWeight: FontWeight.bold,\n                              color: Color(0xFF1E293B),\n                              letterSpacing: 0.3,\n                            ),\n                          ),\n                        ],\n                      ),',
    '// 1. Header: Nomor Laporan & Status Badge\n                Row(\n                  children: [\n                    Flexible(\n                      child: Container(\n                        padding: const EdgeInsets.symmetric(\n                          horizontal: 8,\n                          vertical: 3,\n                        ),\n                        decoration: BoxDecoration(\n                          color: const Color(0xFFF1F5F9),\n                          borderRadius: BorderRadius.circular(6),\n                        ),\n                        child: Row(\n                          mainAxisSize: MainAxisSize.min,\n                          children: [\n                            const Icon(\n                              Icons.tag_rounded,\n                              size: 13,\n                              color: Color(0xFF64748B),\n                            ),\n                            const SizedBox(width: 2),\n                            Flexible(\n                              child: Text(\n                                nomor,\n                                maxLines: 1,\n                                overflow: TextOverflow.ellipsis,\n                                style: const TextStyle(\n                                  fontSize: 11,\n                                  fontWeight: FontWeight.bold,\n                                  color: Color(0xFF1E293B),\n                                  letterSpacing: 0.3,\n                                ),\n                              ),\n                            ),\n                          ],\n                        ),\n                      ),\n                    ),'
  );

  c = c.replace(
    'const Spacer(),\n                    Container(\n                      padding: const EdgeInsets.symmetric(\n                        horizontal: 9,\n                        vertical: 3.5,\n                      ),\n                      decoration: BoxDecoration(\n                        color: statusBg,\n                        borderRadius: BorderRadius.circular(20),\n                      ),\n                      child: Row(\n                        mainAxisSize: MainAxisSize.min,\n                        children: [\n                          Icon(statusIcon, size: 12, color: statusColor),\n                          const SizedBox(width: 4),\n                          Text(\n                            statusLabel.isNotEmpty\n                                ? statusLabel\n                                : _capitalizeFirst(status),\n                            style: TextStyle(\n                              fontSize: 11,\n                              fontWeight: FontWeight.bold,\n                              color: statusColor,\n                            ),\n                          ),\n                        ],\n                      ),',
    'const SizedBox(width: 8),\n                    Flexible(\n                      child: Container(\n                        padding: const EdgeInsets.symmetric(\n                          horizontal: 9,\n                          vertical: 3.5,\n                        ),\n                        decoration: BoxDecoration(\n                          color: statusBg,\n                          borderRadius: BorderRadius.circular(20),\n                        ),\n                        child: Row(\n                          mainAxisSize: MainAxisSize.min,\n                          children: [\n                            Icon(statusIcon, size: 12, color: statusColor),\n                            const SizedBox(width: 4),\n                            Flexible(\n                              child: Text(\n                                statusLabel.isNotEmpty\n                                    ? statusLabel\n                                    : _capitalizeFirst(status),\n                                maxLines: 1,\n                                overflow: TextOverflow.ellipsis,\n                                style: TextStyle(\n                                  fontSize: 11,\n                                  fontWeight: FontWeight.bold,\n                                  color: statusColor,\n                                ),\n                              ),\n                            ),\n                          ],\n                        ),\n                      ),\n                    ),'
  );

  // Footer date wrap in Flexible
  c = c.replace(
    'Row(\n                      children: [\n                        const Icon(\n                          Icons.access_time_rounded,\n                          size: 12.5,\n                          color: Color(0xFF94A3B8),\n                        ),\n                        const SizedBox(width: 4),\n                        Text(\n                          tanggal,\n                          style: const TextStyle(\n                            fontSize: 11,\n                            color: Color(0xFF94A3B8),\n                            fontWeight: FontWeight.w500,\n                          ),\n                        ),\n                      ],\n                    ),',
    'Expanded(\n                      child: Row(\n                        children: [\n                          const Icon(\n                            Icons.access_time_rounded,\n                            size: 12.5,\n                            color: Color(0xFF94A3B8),\n                          ),\n                          const SizedBox(width: 4),\n                          Expanded(\n                            child: Text(\n                              tanggal,\n                              maxLines: 1,\n                              overflow: TextOverflow.ellipsis,\n                              style: const TextStyle(\n                                fontSize: 11,\n                                color: Color(0xFF94A3B8),\n                                fontWeight: FontWeight.w500,\n                              ),\n                            ),\n                          ),\n                        ],\n                      ),\n                    ),'
  );

  fs.writeFileSync(filePath, c, 'utf8');
  console.log('my_laporan_page.dart patched successfully');
}

// 4. Fix step_foto.dart
{
  const filePath = 'lib/features/masyarakat/laporan/presentation/widgets/step_foto.dart';
  let c = fs.readFileSync(filePath, 'utf8');

  // Fix header row: 'Foto Bukti Lapangan' and counter badge overflow on small screen
  c = c.replace(
    'Row(\n              mainAxisAlignment: MainAxisAlignment.spaceBetween,\n              children: [\n                const Text(\n                  \'Foto Bukti Lapangan\',',
    'Row(\n              mainAxisAlignment: MainAxisAlignment.spaceBetween,\n              children: [\n                const Flexible(\n                  child: Text(\n                    \'Foto Bukti Lapangan\',\n                    maxLines: 1,\n                    overflow: TextOverflow.ellipsis,'
  );

  c = c.replace(
    'color: Color(0xFF1E293B),\n                  ),\n                ),\n                Container(',
    'color: Color(0xFF1E293B),\n                  ),\n                ),\n                const SizedBox(width: 6),\n                Flexible(\n                  child: Container('
  );

  c = c.replace(
    'Text(\n                        isMinPhotoMet\n                            ? \'${photos.length}/5 (Min. 3 Terpenuhi ✓)\'\n                            : \'${photos.length}/3 Foto (Kurang $remainingPhotos lagi)\',',
    'Flexible(\n                        child: Text(\n                          isMinPhotoMet\n                              ? \'${photos.length}/5 (Min. 3 ✓)\'\n                              : \'${photos.length}/3 (Kurang $remainingPhotos)\',\n                          maxLines: 1,\n                          overflow: TextOverflow.ellipsis,'
  );

  c = c.replace(
    'color: isMinPhotoMet ? const Color(0xFF16A34A) : const Color(0xFFE11D48),\n                        ),\n                      ),\n                    ],\n                  ),\n                ),\n              ],\n            ),',
    'color: isMinPhotoMet ? const Color(0xFF16A34A) : const Color(0xFFE11D48),\n                          ),\n                        ),\n                      ),\n                    ],\n                  ),\n                ),\n              ),\n            ),'
  );

  fs.writeFileSync(filePath, c, 'utf8');
  console.log('step_foto.dart patched successfully');
}

// 5. Fix step_lokasi.dart
{
  const filePath = 'lib/features/masyarakat/laporan/presentation/widgets/step_lokasi.dart';
  let c = fs.readFileSync(filePath, 'utf8');

  // Change right padding on top-left GPS coordinate badge from 110 to 140 to prevent overlap
  c = c.replace('right: 110,', 'right: 140,');

  fs.writeFileSync(filePath, c, 'utf8');
  console.log('step_lokasi.dart patched successfully');
}

