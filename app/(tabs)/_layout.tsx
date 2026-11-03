import { SymbolView, type SymbolViewProps } from 'expo-symbols';
import { Tabs } from 'expo-router';
import type { ColorValue } from 'react-native';

import Colors from '@/constants/Colors';
import { useClientOnlyValue } from '@/components/useClientOnlyValue';

const c = Colors.dark;

function icon(name: SymbolViewProps['name']) {
  const TabIcon = ({ color }: { color: ColorValue }) => <SymbolView name={name} tintColor={color} size={26} />;
  return TabIcon;
}

export default function TabLayout() {
  return (
    <Tabs
      screenOptions={{
        tabBarActiveTintColor: c.tabIconSelected,
        tabBarInactiveTintColor: c.tabIconDefault,
        tabBarStyle: { backgroundColor: c.card, borderTopColor: c.border },
        headerStyle: { backgroundColor: c.background },
        headerTintColor: c.text,
        // Disable the static render of the header on web
        // to prevent a hydration error in React Navigation v6.
        headerShown: useClientOnlyValue(false, true),
      }}>
      <Tabs.Screen
        name="index"
        options={{ title: 'Odak', tabBarIcon: icon({ ios: 'timer', android: 'timer', web: 'timer' }) }}
      />
      <Tabs.Screen
        name="city"
        options={{
          title: 'Şehir',
          tabBarIcon: icon({ ios: 'building.2', android: 'location_city', web: 'location_city' }),
        }}
      />
      <Tabs.Screen
        name="clan"
        options={{ title: 'Klan', tabBarIcon: icon({ ios: 'shield', android: 'shield', web: 'shield' }) }}
      />
      <Tabs.Screen
        name="profile"
        options={{
          title: 'Profil',
          tabBarIcon: icon({ ios: 'person.crop.circle', android: 'person', web: 'person' }),
        }}
      />
    </Tabs>
  );
}
