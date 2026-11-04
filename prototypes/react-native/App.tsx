import React, { useEffect, useState } from 'react';
import {
  View, Text, StyleSheet, ScrollView, TextInput, Pressable, StatusBar,
  KeyboardAvoidingView, Platform, Modal, Switch, useWindowDimensions,
  BackHandler, Keyboard,
} from 'react-native';
import { SafeAreaProvider, SafeAreaView } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import AsyncStorage from '@react-native-async-storage/async-storage';
import * as DocumentPicker from 'expo-document-picker';

type IconName = React.ComponentProps<typeof Ionicons>['name'];
type Tab = 'Home' | 'Library' | 'Learn' | 'Settings';
type Book = { id: string; title: string; meta: string; sample: boolean };
type Palette = { name: string; primary: string; pale: string; ink: string };
const palettes: Palette[] = [
  { name: 'Emerald', primary: '#007B4C', pale: '#E2F5E9', ink: '#063F2B' },
  { name: 'Indigo', primary: '#4945C5', pale: '#EEECFF', ink: '#292361' },
  { name: 'Ocean', primary: '#006B80', pale: '#DFF3F5', ink: '#074554' },
];
const sampleBooks: Book[] = [
  { id: 'ml', title: 'Introduction to Machine Learning', meta: 'Sample book · 240 pages', sample: true },
  { id: 'ds', title: 'Data Science Foundations', meta: 'Sample book · 128 pages', sample: true },
];
const questions = [
  { q: 'Which task uses labelled training data?', options: ['Supervised learning', 'Clustering', 'Random guessing', 'Data compression'], answer: 0,
    explanation: 'Supervised learning learns a mapping from examples that include both inputs and target labels.', page: 12 },
  { q: 'Which is a classification task?', options: ['Predicting house prices', 'Detecting spam emails', 'Grouping similar customers', 'Compressing an image'], answer: 1,
    explanation: 'Classification predicts a discrete category, such as spam or not spam.', page: 14 },
  { q: 'What does a regression model predict?', options: ['Only text labels', 'Unlabelled groups', 'A continuous value', 'The number of chapters'], answer: 2,
    explanation: 'Regression predicts a numeric value, such as a price or temperature.', page: 15 },
];
const flashcards = [
  { q: 'What is supervised learning?', a: 'Learning from labelled examples to predict a target for new inputs.', page: 12 },
  { q: 'How does classification differ from regression?', a: 'Classification predicts a category. Regression predicts a continuous value.', page: 14 },
  { q: 'Why use a test set?', a: 'To evaluate how well the model generalizes to unseen examples.', page: 18 },
];

function AppBody() {
  const [tab, setTab] = useState<Tab>('Home');
  const [accent, setAccent] = useState(0);
  const [dark, setDark] = useState(false);
  const [books, setBooks] = useState(sampleBooks);
  const [search, setSearch] = useState('');
  const [filter, setFilter] = useState('All books');
  const [mode, setMode] = useState<'Quiz' | 'Flashcards'>('Quiz');
  const [chapter, setChapter] = useState('Chapter 2 · Classification');
  const [topic, setTopic] = useState('Supervised learning');
  const [question, setQuestion] = useState('');
  const [modal, setModal] = useState<'book' | 'source' | 'chapter' | 'ask' | null>(null);
  const [activeBook, setActiveBook] = useState<Book>(sampleBooks[0]);
  const [session, setSession] = useState(false);
  const [index, setIndex] = useState(0);
  const [choice, setChoice] = useState<number | null>(null);
  const [checked, setChecked] = useState(false);
  const [answers, setAnswers] = useState<number[]>([]);
  const [finished, setFinished] = useState(false);
  const [reveal, setReveal] = useState(false);
  const [known, setKnown] = useState<number[]>([]);
  const [source, setSource] = useState({ page: 12, text: questions[0].explanation });
  const [keyboard, setKeyboard] = useState(false);
  const [importError, setImportError] = useState('');
  const { width } = useWindowDimensions();
  const p = palettes[accent];
  const c = { bg: dark ? '#101A16' : '#F7F8F5', surface: dark ? '#1A2821' : '#FFFFFF',
    text: dark ? '#F5F8F5' : '#15231C', muted: dark ? '#B6C7BD' : '#64736A',
    border: dark ? '#34463A' : '#E1E7E0', pale: dark ? '#163E2D' : p.pale,
    primary: dark ? '#64D49B' : p.primary, ink: dark ? '#B6F5D1' : p.ink,
    amber: dark ? '#3C301A' : '#FFF3D9', buttonInk: dark ? '#10291D' : '#FFFFFF', amberText: dark ? '#F5CE77' : '#946000' };
  const s = styles(c);
  const icon = (name: IconName, size = 22, color = c.text) => <Ionicons name={name} size={size} color={color} />;
  useEffect(() => {
    AsyncStorage.getItem('citecoach-preview-style').then((raw) => {
      if (!raw) return;
      try { const v = JSON.parse(raw); if (Number.isInteger(v.accent) && v.accent >= 0 && v.accent < 3) setAccent(v.accent); setDark(v.dark === true); } catch {}
    }).catch(() => {});
    const a = Keyboard.addListener('keyboardDidShow', () => setKeyboard(true));
    const b = Keyboard.addListener('keyboardDidHide', () => setKeyboard(false));
    return () => { a.remove(); b.remove(); };
  }, []);
  useEffect(() => {
    const back = BackHandler.addEventListener('hardwareBackPress', () => {
      if (modal) { setModal(null); return true; }
      if (tab !== 'Home') { setTab('Home'); return true; }
      return false;
    });
    return () => back.remove();
  }, [tab, modal]);
  const navigate = (next: Tab) => { Keyboard.dismiss(); setTab(next); };
  const saveStyle = (a: number, d: boolean) => { setAccent(a); setDark(d); AsyncStorage.setItem('citecoach-preview-style', JSON.stringify({accent: a, dark: d})).catch(() => {}); };
  const start = () => { Keyboard.dismiss(); setSession(true); setIndex(0); setChoice(null); setChecked(false); setAnswers([]); setFinished(false); setReveal(false); setKnown([]); };
  const openLearn = (next: 'Quiz' | 'Flashcards') => { setMode(next); setSession(false); navigate('Learn'); };
  const button = (label: string, onPress: () => void, name?: IconName, testID?: string, disabled = false) => (
    <Pressable testID={testID} accessibilityRole="button" accessibilityLabel={label} disabled={disabled}
      onPress={onPress} style={({pressed}) => [s.primary, disabled && {opacity: .42}, pressed && {opacity: .8}]}>
      {name && icon(name, 20, dark ? '#10291D' : '#FFFFFF')}<Text style={s.primaryText}>{label}</Text>
    </Pressable>
  );
  const pill = (text: string, name: IconName = 'sparkles-outline') => <View style={s.pill}>{icon(name, 14, c.ink)}<Text style={s.pillText}>{text}</Text></View>;
  const section = (title: string, action?: string, onPress?: () => void) => <View style={s.section}><Text style={s.sectionTitle}>{title}</Text>{action && <Pressable onPress={onPress}><Text style={s.link}>{action}</Text></Pressable>}</View>;
  const bookCard = (book: Book, compact = false) => (
    <Pressable key={book.id} testID={'book-' + book.id} accessibilityRole="button" onPress={() => {setActiveBook(book); setModal('book');}}
      style={({pressed}) => [s.book, pressed && {opacity: .75}]}>
      <View style={s.pdf}>{icon('document-text-outline', compact ? 26 : 30, c.amberText)}<Text style={s.pdfText}>PDF</Text></View>
      <View style={{flex: 1, gap: 6}}><Text style={s.bookTitle}>{book.title}</Text><Text style={s.small}>{book.meta}</Text></View>
      {icon('chevron-forward', 20, c.muted)}
    </Pressable>
  );
  const importPdf = async () => {
    try {
      setImportError('');
      const result = await DocumentPicker.getDocumentAsync({type: 'application/pdf', copyToCacheDirectory: true});
      if (!result.canceled) {
        const file = result.assets[0];
        setBooks((previous) => [...previous, {id: String(Date.now()), title: file.name, meta: 'Imported PDF · UI preview', sample: false}]);
      }
    } catch { setImportError('Could not open the PDF picker. Please try again.'); }
  };
  const header = (title: string, subtitle: string) => <View style={{gap: 8}}><Text style={s.heading}>{title}</Text><Text style={s.body}>{subtitle}</Text></View>;
  const home = (
    <>
      <View style={s.top}><Text style={s.brand}>CiteCoach<Text style={{color: c.text}}>·</Text></Text><View style={s.avatar}><Text style={{fontWeight: '700', color: c.ink}}>P</Text></View></View>
      {pill('Interface preview', 'layers-outline')}
      <Text style={s.hero}>Learn something{'\n'}new today.</Text>
      <Text style={[s.body, {marginTop: -12}]}>Your books. Your pace.</Text>
      <View style={s.askCard}>
        <View style={{flexDirection: 'row', gap: 8, alignItems: 'center'}}>{icon('sparkles-outline', 22, c.ink)}<Text style={[s.sectionTitle, {color: c.ink}]}>Ask your textbook</Text></View>
        <Text style={[s.small, {color: c.ink}]}>Turn a question into a moment of clarity.</Text>
        <View style={s.askInput}><TextInput testID="home-question" accessibilityLabel="Question for your textbook" placeholder="What is supervised learning?" placeholderTextColor={c.muted}
          value={question} onChangeText={setQuestion} style={[s.inputText, {flex: 1, minWidth: 0}]} returnKeyType="send"
          onSubmitEditing={() => {Keyboard.dismiss(); setModal('ask');}} />
          <Pressable accessibilityLabel="Ask question" testID="ask-question" onPress={() => {Keyboard.dismiss(); setModal('ask');}} style={s.arrow}>{icon('arrow-forward', 22, dark ? '#10291D' : '#FFFFFF')}</Pressable>
        </View>
      </View>
      <View style={{flexDirection: width < 350 ? 'column' : 'row', gap: 12}}>
        {[{label: 'Create a quiz', sub: 'Put learning to the test', name: 'clipboard-outline' as IconName, mode: 'Quiz' as const},
          {label: 'Flashcards', sub: 'Remember the essentials', name: 'albums-outline' as IconName, mode: 'Flashcards' as const}].map((item) => (
          <Pressable key={item.label} testID={'quick-' + item.mode} accessibilityRole="button" onPress={() => openLearn(item.mode)} style={[s.quick, {flex: width < 350 ? undefined : 1}]}>
            <View style={s.quickIcon}>{icon(item.name, 23, c.ink)}</View><Text style={s.bookTitle}>{item.label}</Text><Text style={s.small}>{item.sub}</Text>
          </Pressable>
        ))}
      </View>
      {section('Continue studying', 'View library', () => navigate('Library'))}
      {bookCard(sampleBooks[0], true)}
      <View style={s.note}>{icon('shield-checkmark-outline', 20, c.muted)}<Text style={[s.small, {flex: 1}]}>Designed for private, on-device learning. AI is not connected in this UI preview.</Text></View>
    </>
  );
  const library = (
    <>
      {header('Your library', 'A little knowledge, always within reach.')}
      <View style={s.search}>{icon('search-outline', 20, c.muted)}<TextInput testID="library-search" accessibilityLabel="Search books" placeholder="Search your books" placeholderTextColor={c.muted} value={search} onChangeText={setSearch} style={[s.inputText, {flex: 1}]} /></View>
      <View style={s.chips}>{['All books', 'Recent'].map((f) => <Pressable key={f} onPress={() => setFilter(f)} style={[s.chip, filter === f && s.chipActive]}><Text style={[s.chipText, filter === f && {color: dark ? '#10291D' : '#FFFFFF'}]}>{f}</Text></Pressable>)}</View>
      {section(String(books.length) + ' books', 'PDF collection')}
      {(filter === 'Recent' ? [...books].reverse() : books).filter((b) => b.title.toLowerCase().includes(search.toLowerCase())).map((b) => bookCard(b))}
      {books.filter((b) => b.title.toLowerCase().includes(search.toLowerCase())).length === 0 && <View style={s.empty}>{icon('search-outline', 32, c.muted)}<Text style={s.bookTitle}>No matching books</Text><Text style={s.small}>Try a different title.</Text></View>}
      {importError ? <Text accessibilityRole="alert" style={{color: '#B23C32'}}>{importError}</Text> : null}
      {button('Import a PDF', importPdf, 'add-outline', 'import-pdf')}
    </>
  );
  const current = questions[index];
  const currentCard = flashcards[index];
  const score = answers.filter((value, i) => value === questions[i].answer).length;
  const learn = (
    <>
      {header('Make it stick.', 'Build confidence, one idea at a time.')}
      <View style={s.segments}>{(['Quiz','Flashcards'] as const).map((m) => <Pressable key={m} testID={'mode-' + m} onPress={() => {setMode(m); setSession(false);}} style={[s.segment, mode === m && {backgroundColor: c.primary}]}><Text style={[s.segmentText, mode === m && {color: dark ? '#10291D' : '#FFFFFF'}]}>{m}</Text></Pressable>)}</View>
      {!session ? <>
        <View style={s.card}>
          <Text style={s.fieldLabel}>STUDY BOOK</Text><Text style={s.bookTitle}>Introduction to Machine Learning</Text>
          <View style={s.divider} />
          <Text style={s.fieldLabel}>CHAPTER</Text>
          <Pressable testID="choose-chapter" onPress={() => setModal('chapter')} style={s.select}><Text style={[s.body, {flex: 1, color: c.text}]}>{chapter}</Text>{icon('chevron-down', 20, c.muted)}</Pressable>
          <Text style={s.fieldLabel}>TOPIC</Text><TextInput accessibilityLabel="Study topic" value={topic} onChangeText={setTopic} placeholder="What would you like to study?" placeholderTextColor={c.muted} style={s.textField} />
        </View>
        <View style={s.note}>{icon('information-circle-outline', 20, c.muted)}<Text style={[s.small, {flex: 1}]}>Try the study flow with sample questions. Offline AI generation will be connected in the full app.</Text></View>
        {button(mode === 'Quiz' ? 'Try sample quiz' : 'Try sample flashcards', start, 'play-outline', 'start-session')}
      </> : mode === 'Quiz' ? finished ? <>
        <View style={[s.card, {alignItems: 'center', gap: 18, paddingVertical: 32}]}>
          <View style={[s.quickIcon, {width: 64, height: 64, borderRadius: 32}]}>{icon('trophy-outline', 32, c.ink)}</View>
          <Text style={s.heading}>Nice work.</Text><Text testID="quiz-score" style={{fontSize: 46, fontWeight: '800', color: c.primary}}>{score} / {questions.length}</Text>
          <Text style={[s.body, {textAlign: 'center'}]}>Every question is another step forward.</Text>
        </View>
        {button('Retake sample quiz', start, 'refresh-outline')}
        <Pressable onPress={() => setSession(false)} style={s.outline}><Text style={s.link}>Choose another chapter</Text></Pressable>
      </> : <>
        <View style={s.progressRow}><Text style={s.link}>Question {index + 1} of {questions.length}</Text><Text style={s.small}>Sample quiz</Text></View>
        <View style={s.track}><View style={[s.fill, {width: String((index + 1) / questions.length * 100) + '%' as any}]} /></View>
        <Text style={s.question}>{current.q}</Text>
        <View style={{gap: 12}}>{current.options.map((option, i) => <Pressable key={option} testID={'answer-' + i} disabled={checked} accessibilityRole="button" accessibilityState={{selected: choice === i}}
          onPress={() => setChoice(i)} style={[s.option, choice === i && {borderColor: c.primary, backgroundColor: c.pale}, checked && i === current.answer && {borderColor: c.primary, backgroundColor: c.pale}]}>
          <View style={[s.letter, choice === i && {backgroundColor: c.primary}]}><Text style={{fontWeight: '700', color: choice === i ? (dark ? '#10291D' : '#FFFFFF') : c.ink}}>{'ABCD'[i]}</Text></View>
          <Text style={[s.body, {flex: 1, color: c.text}]}>{option}</Text>
          {checked && i === current.answer && icon('checkmark-circle', 22, c.primary)}
        </Pressable>)}</View>
        {checked ? <View style={[s.card, {backgroundColor: c.pale}]}><Text testID="answer-feedback" style={[s.bookTitle, {color: c.ink}]}>{choice === current.answer ? 'You got it.' : 'A chance to learn.'}</Text><Text style={[s.body, {color: c.ink}]}>{current.explanation}</Text><Pressable onPress={() => {setSource({page: current.page, text: current.explanation}); setModal('source');}}><Text style={s.link}>View sample source · page {current.page}</Text></Pressable></View> : null}
        {button(checked ? (index === questions.length - 1 ? 'See my results' : 'Next question') : 'Check answer', () => {
          if (!checked) {setAnswers((previous) => [...previous, choice!]); setChecked(true);}
          else if (index === questions.length - 1) setFinished(true);
          else {setIndex(index + 1); setChoice(null); setChecked(false);}
        }, checked ? 'arrow-forward-outline' : 'checkmark-outline', 'quiz-action', !checked && choice === null)}
      </> : <>
        <View style={s.progressRow}><Text style={s.link}>Card {index + 1} of {flashcards.length}</Text><Text style={s.small}>{known.length} remembered</Text></View>
        <View style={[s.card, {paddingVertical: 30, minHeight: 240, justifyContent: 'center'}]}>
          {pill('Sample flashcard', 'albums-outline')}<Text style={s.question}>{currentCard.q}</Text>
          {reveal ? <><View style={s.divider} /><Text style={s.body}>{currentCard.a}</Text><Pressable onPress={() => {setSource({page: currentCard.page, text: currentCard.a}); setModal('source');}}><Text style={s.link}>View sample source · page {currentCard.page}</Text></Pressable></> : <Pressable onPress={() => setReveal(true)} style={s.outline}><Text style={s.link}>Reveal answer</Text></Pressable>}
        </View>
        {reveal && button(known.includes(index) ? 'Remembered' : 'I remembered this', () => setKnown((previous) => previous.includes(index) ? previous : [...previous, index]), 'checkmark-circle-outline')}
        {button(index === flashcards.length - 1 ? 'Start again' : 'Next card', () => {setIndex((index + 1) % flashcards.length); setReveal(false);}, 'arrow-forward-outline')}
      </>}
    </>
  );
  const settings = (
    <>
      {header('Make it yours.', 'A calm space for focused learning.')}
      {section('Color palette')}
      <View style={s.card}><View style={{flexDirection: 'row', gap: 12, flexWrap: 'wrap'}}>{palettes.map((color, i) => <Pressable key={color.name} testID={'palette-' + color.name} onPress={() => saveStyle(i, dark)} style={{alignItems: 'center', gap: 9, flex: 1, minWidth: 72}}>
        <View style={{width: 54, height: 54, borderRadius: 27, backgroundColor: color.primary, alignItems: 'center', justifyContent: 'center', borderWidth: accent === i ? 3 : 0, borderColor: c.text}}>{accent === i && icon('checkmark', 24, '#FFFFFF')}</View><Text style={s.small}>{color.name}</Text>
      </Pressable>)}</View></View>
      <View style={s.card}><View style={s.progressRow}><View style={{flex: 1, gap: 5}}><Text style={s.bookTitle}>Dark appearance</Text><Text style={s.small}>A softer screen after hours</Text></View><Switch accessibilityLabel="Dark appearance" value={dark} onValueChange={(value) => saveStyle(accent, value)} trackColor={{true: c.primary, false: c.border}} /></View></View>
      {section('Offline AI')}
      <View style={s.card}><View style={{flexDirection: 'row', gap: 12}}><View style={s.quickIcon}>{icon('hardware-chip-outline', 24, c.ink)}</View><View style={{flex: 1, gap: 7}}><Text style={s.bookTitle}>Your private study companion</Text><Text style={s.body}>The offline model is not connected in this UI preview.</Text></View></View></View>
      {section('About this preview')}
      <View style={s.card}><Text style={s.body}>Explore the layout, colors, navigation, and sample study flows. This is a separate preview app and does not replace your current CiteCoach installation.</Text></View>
      <Text style={[s.small, {textAlign: 'center', marginVertical: 12}]}>CiteCoach · React Native UI preview 0.1</Text>
    </>
  );
  return (
    <SafeAreaView style={{flex: 1, backgroundColor: c.bg}} edges={['top','bottom']}>
      <StatusBar barStyle={dark ? 'light-content' : 'dark-content'} backgroundColor={c.bg} />
      <KeyboardAvoidingView style={{flex: 1}} behavior={Platform.OS === 'ios' ? 'padding' : 'height'}>
        <ScrollView key={tab + String(session) + String(index)} testID="screen-scroll" style={{flex: 1}} contentContainerStyle={{padding: width < 350 ? 18 : 24, gap: 20, width: '100%', maxWidth: 640, alignSelf: 'center', paddingBottom: 32}}
          keyboardShouldPersistTaps="handled" keyboardDismissMode="on-drag">
          {tab === 'Home' ? home : tab === 'Library' ? library : tab === 'Learn' ? learn : settings}
        </ScrollView>
        {!keyboard && <View style={s.nav}>{([{tab:'Home', icon:'home-outline'},{tab:'Library',icon:'folder-open-outline'},{tab:'Learn',icon:'school-outline'},{tab:'Settings',icon:'settings-outline'}] as {tab: Tab; icon: IconName}[]).map((item) => (
          <Pressable key={item.tab} testID={'nav-' + item.tab} accessibilityRole="tab" accessibilityState={{selected: tab === item.tab}} onPress={() => navigate(item.tab)} style={s.navItem}>
            <View style={[s.navIcon, tab === item.tab && {backgroundColor: c.pale}]}>{icon(item.icon, 23, tab === item.tab ? c.primary : c.muted)}</View><Text style={[s.navLabel, tab === item.tab && {color: c.primary, fontWeight: '700'}]}>{item.tab}</Text>
          </Pressable>))}</View>}
      </KeyboardAvoidingView>
      <Modal visible={modal !== null} transparent animationType="slide" onRequestClose={() => setModal(null)}>
        <View style={s.scrim}><SafeAreaView style={[s.sheet, {maxHeight: '85%'}]} edges={['bottom']}>
          <View style={s.sheetTop}><View style={s.handle} /><Pressable accessibilityLabel="Close" testID="close-modal" onPress={() => setModal(null)} style={{padding: 10}}>{icon('close', 24)}</Pressable></View>
          <ScrollView contentContainerStyle={{paddingHorizontal: 24, paddingBottom: 28, gap: 18}} keyboardShouldPersistTaps="handled">
            {modal === 'chapter' ? <><Text style={s.heading}>Choose a chapter</Text><Text style={s.small}>Sample textbook chapters</Text>{['Whole book','Chapter 1 · Getting started','Chapter 2 · Classification','Chapter 3 · Regression'].map((value) => <Pressable key={value} testID={'chapter-' + value.split(' ')[1]} onPress={() => {setChapter(value); setModal(null); setSession(false);}} style={s.select}><Text style={[s.body, {flex: 1, color: c.text}]}>{value}</Text>{chapter === value && icon('checkmark-circle', 22, c.primary)}</Pressable>)}</> : modal === 'source' ? <><Text style={s.heading}>Sample source</Text>{pill('PDF page ' + source.page, 'document-text-outline')}<View style={[s.card, {backgroundColor: c.pale}]}><Text style={[s.body, {color: c.ink}]}>{source.text}</Text></View><Text style={s.small}>A sample excerpt for evaluating the citation interface.</Text></> : modal === 'ask' ? <><Text style={s.heading}>Ask your textbook</Text><Text style={s.bookTitle}>{question || 'What is supervised learning?'}</Text><View style={s.note}>{icon('information-circle-outline', 22, c.muted)}<Text style={[s.body, {flex: 1}]}>Offline AI is not connected in this UI preview. You can explore the sample quiz and flashcards.</Text></View>{button('Explore sample quiz', () => {setModal(null); openLearn('Quiz');}, 'arrow-forward-outline')}</> : <><View style={s.pdf}>{icon('document-text-outline', 30, c.amberText)}</View><Text style={s.heading}>{activeBook.title}</Text><Text style={s.body}>{activeBook.meta}</Text><Text style={s.small}>{activeBook.sample ? 'Explore the sample learning flow for this book.' : 'This PDF has been imported. Reading and AI processing are not connected in this UI preview.'}</Text>{activeBook.sample && button('Start studying', () => {setModal(null); openLearn('Quiz');}, 'school-outline')}</>}
          </ScrollView>
        </SafeAreaView></View>
      </Modal>
    </SafeAreaView>
  );
}

function styles(c: any) { return StyleSheet.create({
  top: {flexDirection:'row', alignItems:'center', justifyContent:'space-between'},
  brand: {fontSize:29, letterSpacing:-1.1, fontWeight:'800', color:c.primary},
  avatar:{width:40,height:40,borderRadius:20,backgroundColor:c.pale,alignItems:'center',justifyContent:'center'},
  pill:{alignSelf:'flex-start',flexDirection:'row',alignItems:'center',gap:6,backgroundColor:c.pale,borderRadius:9,paddingHorizontal:10,paddingVertical:7},
  pillText:{fontSize:12,fontWeight:'600',color:c.ink},
  hero:{fontSize:38,lineHeight:44,letterSpacing:-1.3,fontWeight:'800',color:c.text},
  heading:{fontSize:30,lineHeight:37,letterSpacing:-.9,fontWeight:'800',color:c.text},
  body:{fontSize:15,lineHeight:23,color:c.muted},
  small:{fontSize:12,lineHeight:18,color:c.muted},
  section:{flexDirection:'row',alignItems:'center',justifyContent:'space-between',gap:12,flexWrap:'wrap',marginTop:4},
  sectionTitle:{fontSize:19,fontWeight:'700',letterSpacing:-.4,color:c.text},
  link:{fontSize:13,lineHeight:20,fontWeight:'700',color:c.primary},
  askCard:{backgroundColor:c.pale,borderRadius:24,padding:20,gap:12},
  askInput:{flexDirection:'row',alignItems:'center',gap:8,backgroundColor:c.surface,borderRadius:15,padding:8,paddingLeft:13,minHeight:58},
  inputText:{fontSize:14,color:c.text,paddingVertical:8},
  arrow:{width:40,height:40,borderRadius:20,backgroundColor:c.primary,alignItems:'center',justifyContent:'center'},
  quick:{backgroundColor:c.surface,borderWidth:1,borderColor:c.border,borderRadius:19,padding:18,gap:9},
  quickIcon:{width:43,height:43,borderRadius:14,backgroundColor:c.pale,alignItems:'center',justifyContent:'center'},
  book:{flexDirection:'row',alignItems:'center',gap:14,backgroundColor:c.surface,borderWidth:1,borderColor:c.border,borderRadius:20,padding:17},
  pdf:{width:51,minHeight:66,borderRadius:13,backgroundColor:c.amber,alignItems:'center',justifyContent:'center',gap:2,paddingVertical:8},
  pdfText:{fontSize:10,fontWeight:'800',color:c.amberText},
  bookTitle:{fontSize:16,lineHeight:22,fontWeight:'700',letterSpacing:-.2,color:c.text},
  note:{flexDirection:'row',gap:10,alignItems:'flex-start',paddingVertical:3},
  primary:{backgroundColor:c.primary,borderRadius:16,minHeight:54,padding:15,flexDirection:'row',alignItems:'center',justifyContent:'center',gap:9},
  primaryText:{color:c.buttonInk,fontSize:15,fontWeight:'700',flexShrink:1,textAlign:'center'},
  search:{borderWidth:1,borderColor:c.border,borderRadius:15,backgroundColor:c.surface,paddingHorizontal:14,paddingVertical:7,flexDirection:'row',alignItems:'center',gap:10},
  chips:{flexDirection:'row',flexWrap:'wrap',gap:10},
  chip:{paddingHorizontal:20,paddingVertical:10,borderRadius:20,borderWidth:1,borderColor:c.border,backgroundColor:c.surface},
  chipActive:{backgroundColor:c.primary,borderColor:c.primary},
  chipText:{fontSize:13,fontWeight:'600',color:c.muted},
  segments:{backgroundColor:c.surface,borderRadius:16,padding:5,borderWidth:1,borderColor:c.border,flexDirection:'row',gap:5},
  segment:{flex:1,paddingHorizontal:10,paddingVertical:12,borderRadius:12,alignItems:'center'},
  segmentText:{fontSize:14,fontWeight:'700',color:c.muted},
  card:{backgroundColor:c.surface,borderWidth:1,borderColor:c.border,borderRadius:22,padding:20,gap:14},
  fieldLabel:{fontSize:10,letterSpacing:1.3,fontWeight:'700',color:c.muted},
  divider:{height:1,backgroundColor:c.border,marginVertical:3},
  select:{flexDirection:'row',alignItems:'center',gap:10,borderWidth:1,borderColor:c.border,borderRadius:13,padding:13},
  textField:{borderWidth:1,borderColor:c.border,borderRadius:13,padding:13,color:c.text,fontSize:14},
  progressRow:{flexDirection:'row',alignItems:'center',justifyContent:'space-between',gap:10,flexWrap:'wrap'},
  track:{height:5,borderRadius:3,backgroundColor:c.border,overflow:'hidden'},
  fill:{height:5,borderRadius:3,backgroundColor:c.primary},
  question:{fontSize:24,lineHeight:32,fontWeight:'700',letterSpacing:-.4,color:c.text},
  option:{borderWidth:1.5,borderColor:c.border,backgroundColor:c.surface,borderRadius:16,padding:14,flexDirection:'row',gap:12,alignItems:'center',minHeight:64},
  letter:{width:33,height:33,borderRadius:10,backgroundColor:c.pale,alignItems:'center',justifyContent:'center'},
  outline:{borderWidth:1,borderColor:c.border,borderRadius:14,padding:15,alignItems:'center'},
  empty:{padding:30,gap:12,alignItems:'center'},
  nav:{backgroundColor:c.surface,borderTopWidth:1,borderTopColor:c.border,flexDirection:'row',paddingTop:9,paddingBottom:7},
  navItem:{flex:1,alignItems:'center',gap:4,paddingVertical:4},
  navIcon:{paddingHorizontal:17,paddingVertical:6,borderRadius:16},
  navLabel:{fontSize:10,color:c.muted},
  scrim:{flex:1,backgroundColor:'rgba(10,25,17,.42)',justifyContent:'flex-end'},
  sheet:{backgroundColor:c.surface,borderTopLeftRadius:28,borderTopRightRadius:28,width:'100%',maxWidth:640,alignSelf:'center'},
  sheetTop:{padding:12,flexDirection:'row',alignItems:'center',justifyContent:'flex-end'},
  handle:{position:'absolute',top:12,left:'44%',width:44,height:4,borderRadius:2,backgroundColor:c.border},
}); }

export default function App() { return <SafeAreaProvider><AppBody /></SafeAreaProvider>; }
