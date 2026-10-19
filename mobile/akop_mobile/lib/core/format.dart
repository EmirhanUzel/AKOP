const _months = ['Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', 'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'];

String _two(int n) => n.toString().padLeft(2, '0');

/// "14 Eki, 09:12"
String formatShort(DateTime d) => '${d.day} ${_months[d.month - 1]}, ${_two(d.hour)}:${_two(d.minute)}';

/// "14 Eki 2026, 09:12"
String formatLong(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}, ${_two(d.hour)}:${_two(d.minute)}';
