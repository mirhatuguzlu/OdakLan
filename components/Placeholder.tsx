import { StyleSheet } from 'react-native';

import { Text, View } from '@/components/Themed';
import Colors from '@/constants/Colors';

// Temporary screen body until the step that implements it (see plan).
export function Placeholder({ title, hint }: { title: string; hint: string }) {
  return (
    <View style={styles.container}>
      <Text style={styles.title}>{title}</Text>
      <Text style={styles.hint}>{hint}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, alignItems: 'center', justifyContent: 'center', padding: 24 },
  title: { fontSize: 24, fontWeight: 'bold', color: Colors.dark.tint },
  hint: { marginTop: 8, color: Colors.dark.textMuted, textAlign: 'center' },
});
