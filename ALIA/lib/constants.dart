// ─────────────────────────────────────────────
//  CHANGE THIS to your computer's local IP
//  Find it with: ipconfig (Windows) or hostname -I (Linux/Mac)
//  Example: 'http://192.168.1.42:8000'
// ─────────────────────────────────────────────
const String baseUrl = 'http://192.168.1.8:8000';

const Map<int, String> priorityLabels = {
  1: 'High',
  2: 'Medium',
  3: 'Low',
};

const Map<int, String> priorityEmojis = {
  1: '🔴',
  2: '🟡',
  3: '🟢',
};
