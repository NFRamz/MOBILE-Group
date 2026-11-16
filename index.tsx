// 1.1 IMPORT SECTION
import { useAuth } from '@/context/AuthContext';
import { supabase } from '@/lib/supabase';
import { useRouter } from 'expo-router';
import { StatusBar } from 'expo-status-bar';
import { useCallback, useEffect, useState } from 'react';
import {
  ActivityIndicator,
  Alert,
  FlatList,
  Keyboard,
  RefreshControl,
  StyleSheet,
  Text,
  TextInput,
  TouchableOpacity,
  View
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

// 1.2 INTERFACE DEFINITION
interface Mission {
  id: string;
  title: string;
  reward_points: number;
  status: 'pending' | 'completed';
  created_at: string;
}

export default function TacticalHQScreen() {
  // 1.3 COMPONENT STATE
  const { user, signOut } = useAuth();
  const router = useRouter();
  const [missions, setMissions] = useState<Mission[]>([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [missionTitle, setMissionTitle] = useState('');
  const [rewardXP, setRewardXP] = useState('150');
  const [submitting, setSubmitting] = useState(false);

  // 1.4 SUPABASE CRUD OPERATIONS
  // 2.1 READ: FETCH MISSIONS (PROTECTED BY RLS)
  const fetchMissions = useCallback(async () => {
    try {
      const { data, error } = await supabase
        .from('missions')
        ./*???*/('*')
        .order('created_at', { ascending: false });

      if (error) {
        if (error.code === 'PGRST205' || error.message.includes('does not exist')) {
          Alert.alert(
            'Database Setup Required',
            'Table "missions" not found! Run the SQL schema (code4.sql) in your Supabase SQL Editor.'
          );
        } else {
          throw error;
        }
      }
      setMissions(data || []);
    } catch (error: any) {
      Alert.alert('Sync Error', error.message || 'Failed to fetch mission board.');
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  }, []);

  useEffect(() => {
    fetchMissions();
  }, [fetchMissions]);

  const onRefresh = () => {
    setRefreshing(true);
    fetchMissions();
  };

  // 2.2 CREATE: INSERT MISSION
  const handleCreateMission = async () => {
    if (!missionTitle.trim()) {
      Alert.alert('Objective Missing', 'Please enter an objective for the mission.');
      return;
    }

    const points = parseInt(rewardXP, 10) || 100;
    try {
      setSubmitting(true);
      const { error } = await supabase.from('missions')./*???*/([
        {
          title: missionTitle.trim(),
          reward_points: points,
          user_id: user?.id,
        },
      ]);

      if (error) throw error;
      setMissionTitle('');
      setRewardXP('150');
      Keyboard.dismiss();
      fetchMissions();
    } catch (error: any) {
      Alert.alert('Dispatch Failed', error.message);
    } finally {
      setSubmitting(false);
    }
  };

  // 2.3 UPDATE: TOGGLE STATUS (OPTIMISTIC UI)
  const handleToggleStatus = async (item: Mission) => {
    const nextStatus = item.status === 'completed' ? 'pending' : 'completed';

    // Instant local UI state update
    setMissions((prev) =>
      prev.map((m) => (m.id === item.id ? { ...m, status: nextStatus } : m))
    );

    try {
      const { error } = await supabase
        .from('missions')
        ./*???*/({ status: nextStatus })
        .eq('id', item.id);

      if (error) throw error;
    } catch (error: any) {
      Alert.alert('Update Failed', error.message);
      fetchMissions();
    }
  };

  // 2.4 DELETE: REMOVE MISSION (OPTIMISTIC UI)
  const handleDeleteMission = async (id: string) => {
    // Instant local removal
    setMissions((prev) => prev.filter((m) => m.id !== id));

    try {
      const { error } = await supabase.from('missions')./*???*/().eq('id', id);
      if (error) throw error;
    } catch (error: any) {
      Alert.alert('Deletion Failed', error.message);
      fetchMissions();
    }
  };

  // 1.5 LIST ITEM RENDER
  const renderMissionItem = ({ item }: { item: Mission }) => {
    const isDone = item.status === 'completed';
    return (
      <View style={styles.missionCard}>
        <TouchableOpacity
          style={styles.missionMainTouch}
          onPress={() => handleToggleStatus(item)}
          activeOpacity={0.75}
        >
          {/* STATUS CHIP */}
          <View style={[styles.statusChip, isDone ? styles.statusChipDone : styles.statusChipActive]}>
            <View style={[styles.statusDot, isDone ? styles.statusDotDone : styles.statusDotActive]} />
            <Text style={[styles.statusChipText, isDone ? styles.statusTextDone : styles.statusTextActive]}>
              {isDone ? 'DONE' : 'ACTIVE'}
            </Text>
          </View>

          <View style={styles.missionTextContent}>
            <Text
              style={[styles.missionTitle, isDone && styles.missionTitleDone]}
              numberOfLines={2}
            >
              {item.title}
            </Text>
            <Text style={styles.rewardText}>+{item.reward_points} XP</Text>
          </View>
        </TouchableOpacity>

        <TouchableOpacity
          style={styles.deleteChip}
          onPress={() => handleDeleteMission(item.id)}
          activeOpacity={0.7}
        >
          <Text style={styles.deleteChipText}>✕</Text>
        </TouchableOpacity>
      </View>
    );
  };

  // 1.6 COMPACT SCREEN RENDER
  return (
    <SafeAreaView style={styles.safeArea}>
      <StatusBar style="light" />
      <View style={styles.container}>

        {/* HEADER SECTION */}
        <View style={styles.header}>
          <View style={styles.headerLeft}>
            <View style={styles.statusIndicatorRow}>
              <View style={styles.livePulseDot} />
              <Text style={styles.statusLabel}>COMMAND HQ ACTIVE</Text>
            </View>
            <Text style={styles.callsignHeading}>
              {user?.user_metadata?.callsign || user?.email?.split('@')[0] || 'Operative'}
            </Text>
            <Text style={styles.emailSub} numberOfLines={1}>
              {user?.email}
            </Text>
          </View>

          <View style={{ flexDirection: 'row', gap: 8 }}>
            <TouchableOpacity style={styles.signOutButton} onPress={() => router.push('/health')} activeOpacity={0.8}>
              <Text style={styles.signOutButtonText}>Health</Text>
            </TouchableOpacity>
            <TouchableOpacity style={styles.signOutButton} onPress={() => router.push('/vault')} activeOpacity={0.8}>
              <Text style={styles.signOutButtonText}>Vault</Text>
            </TouchableOpacity>
            <TouchableOpacity style={styles.signOutButton} onPress={signOut} activeOpacity={0.8}>
              <Text style={styles.signOutButtonText}>Sign Out</Text>
            </TouchableOpacity>
          </View>
        </View>

        {/* DISPATCH NEW MISSION CARD */}
        <View style={styles.dispatchCard}>
          <Text style={styles.cardHeaderLabel}>DISPATCH NEW MISSION</Text>
          <TextInput
            style={styles.mainInput}
            placeholder="Mission objective..."
            placeholderTextColor="#71717a"
            value={missionTitle}
            onChangeText={setMissionTitle}
          />
          <View style={styles.dispatchRow}>
            <TextInput
              style={[styles.mainInput, styles.xpInput]}
              placeholder="XP"
              placeholderTextColor="#71717a"
              value={rewardXP}
              onChangeText={setRewardXP}
              keyboardType="numeric"
            />
            <TouchableOpacity
              style={[styles.dispatchButton, submitting && styles.buttonDisabled]}
              onPress={handleCreateMission}
              disabled={submitting}
              activeOpacity={0.85}
            >
              {submitting ? (
                <ActivityIndicator color="#09090b" size="small" />
              ) : (
                <Text style={styles.dispatchButtonText}>Dispatch</Text>
              )}
            </TouchableOpacity>
          </View>
        </View>

        {/* ACTIVE MISSIONS LIST HEADER */}
        <View style={styles.listSectionHeader}>
          <Text style={styles.listTitle}>TACTICAL MISSIONS</Text>
          <View style={styles.badgeCountPill}>
            <Text style={styles.badgeCountText}>{missions.length} QUEUED</Text>
          </View>
        </View>

        {/* LIST / LOADING / EMPTY STATE */}
        {loading ? (
          <View style={styles.loadingContainer}>
            <ActivityIndicator size="small" color="#fafafa" />
            <Text style={styles.loadingText}>Syncing with PostgreSQL...</Text>
          </View>
        ) : (
          <FlatList
            data={missions}
            keyExtractor={(item) => item.id}
            renderItem={renderMissionItem}
            contentContainerStyle={styles.listContent}
            showsVerticalScrollIndicator={false}
            refreshControl={
              <RefreshControl refreshing={refreshing} onRefresh={onRefresh} tintColor="#fafafa" />
            }
            ListEmptyComponent={
              <View style={styles.emptyState}>
                <Text style={styles.emptyTitle}>No active missions</Text>
                <Text style={styles.emptySubtitle}>
                  All sectors are secure. Dispatch a new objective above.
                </Text>
              </View>
            }
          />
        )}

      </View>
    </SafeAreaView>
  );
}

// 1.7 BULLETPROOF STYLESHEET
const styles = StyleSheet.create({
  safeArea: {
    flex: 1,
    backgroundColor: '#09090b',
  },
  container: {
    flex: 1,
    paddingHorizontal: 16,
    paddingTop: 8,
    maxWidth: 420,
    width: '100%',
    alignSelf: 'center',
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 12,
    paddingBottom: 10,
    borderBottomWidth: 1,
    borderBottomColor: '#18181b',
  },
  headerLeft: {
    flex: 1,
    marginRight: 10,
  },
  statusIndicatorRow: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 2,
  },
  livePulseDot: {
    width: 6,
    height: 6,
    borderRadius: 3,
    backgroundColor: '#22c55e',
    marginRight: 6,
  },
  statusLabel: {
    color: '#71717a',
    fontSize: 9,
    fontWeight: '800',
    letterSpacing: 1,
  },
  callsignHeading: {
    color: '#fafafa',
    fontSize: 18,
    fontWeight: '800',
  },
  emailSub: {
    color: '#71717a',
    fontSize: 11,
    marginTop: 1,
  },
  signOutButton: {
    backgroundColor: '#18181b',
    paddingHorizontal: 10,
    paddingVertical: 6,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: '#27272a',
  },
  signOutButtonText: {
    color: '#a1a1aa',
    fontWeight: '700',
    fontSize: 11,
  },
  dispatchCard: {
    backgroundColor: '#121215',
    borderRadius: 12,
    padding: 12,
    borderWidth: 1,
    borderColor: '#27272a',
    marginBottom: 12,
  },
  cardHeaderLabel: {
    color: '#71717a',
    fontSize: 9,
    fontWeight: '800',
    letterSpacing: 0.8,
    marginBottom: 6,
  },
  mainInput: {
    backgroundColor: '#18181b',
    color: '#fafafa',
    height: 40,
    paddingHorizontal: 12,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: '#27272a',
    fontSize: 13,
    marginBottom: 8,
  },
  dispatchRow: {
    flexDirection: 'row',
  },
  xpInput: {
    flex: 1,
    marginRight: 8,
    marginBottom: 0,
  },
  dispatchButton: {
    backgroundColor: '#fafafa',
    height: 40,
    paddingHorizontal: 16,
    borderRadius: 8,
    justifyContent: 'center',
    alignItems: 'center',
  },
  buttonDisabled: {
    opacity: 0.5,
  },
  dispatchButtonText: {
    color: '#09090b',
    fontWeight: '700',
    fontSize: 13,
  },
  listSectionHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 8,
  },
  listTitle: {
    color: '#71717a',
    fontSize: 10,
    fontWeight: '800',
    letterSpacing: 0.8,
  },
  badgeCountPill: {
    backgroundColor: '#18181b',
    paddingHorizontal: 8,
    paddingVertical: 2,
    borderRadius: 10,
    borderWidth: 1,
    borderColor: '#27272a',
  },
  badgeCountText: {
    color: '#a1a1aa',
    fontSize: 9,
    fontWeight: '800',
    letterSpacing: 0.5,
  },
  listContent: {
    paddingBottom: 20,
  },
  missionCard: {
    backgroundColor: '#121215',
    borderRadius: 10,
    padding: 10,
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 8,
    borderWidth: 1,
    borderColor: '#27272a',
  },
  missionMainTouch: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
  },
  statusChip: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 6,
    paddingVertical: 3,
    borderRadius: 6,
    marginRight: 8,
    borderWidth: 1,
  },
  statusChipActive: {
    backgroundColor: '#18181b',
    borderColor: '#3f3f46',
  },
  statusChipDone: {
    backgroundColor: '#18181b',
    borderColor: '#27272a',
  },
  statusDot: {
    width: 5,
    height: 5,
    borderRadius: 2.5,
    marginRight: 4,
  },
  statusDotActive: {
    backgroundColor: '#fafafa',
  },
  statusDotDone: {
    backgroundColor: '#52525b',
  },
  statusChipText: {
    fontSize: 9,
    fontWeight: '800',
    letterSpacing: 0.5,
  },
  statusTextActive: {
    color: '#fafafa',
  },
  statusTextDone: {
    color: '#71717a',
  },
  missionTextContent: {
    flex: 1,
    marginRight: 6,
  },
  missionTitle: {
    color: '#fafafa',
    fontSize: 13,
    fontWeight: '600',
    lineHeight: 16,
  },
  missionTitleDone: {
    textDecorationLine: 'line-through',
    color: '#52525b',
  },
  rewardText: {
    color: '#71717a',
    fontSize: 10,
    fontWeight: '600',
    marginTop: 1,
  },
  deleteChip: {
    width: 26,
    height: 26,
    borderRadius: 6,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#18181b',
    borderWidth: 1,
    borderColor: '#27272a',
  },
  deleteChipText: {
    color: '#71717a',
    fontSize: 10,
    fontWeight: '700',
  },
  loadingContainer: {
    alignItems: 'center',
    marginTop: 30,
  },
  loadingText: {
    color: '#71717a',
    fontSize: 11,
    marginTop: 6,
  },
  emptyState: {
    alignItems: 'center',
    marginTop: 30,
    paddingHorizontal: 16,
  },
  emptyTitle: {
    color: '#fafafa',
    fontSize: 13,
    fontWeight: '700',
    marginBottom: 2,
  },
  emptySubtitle: {
    color: '#71717a',
    fontSize: 11,
    textAlign: 'center',
    lineHeight: 14,
  },
});
