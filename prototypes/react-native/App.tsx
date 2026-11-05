import React, { useEffect, useState } from 'react';
import {
  View, Text as NativeText, type TextProps, StyleSheet, ScrollView, TextInput, Pressable, StatusBar,
  KeyboardAvoidingView, Platform, Modal, Switch, useWindowDimensions,
  BackHandler, Keyboard,
} from 'react-native';
import { SafeAreaProvider, SafeAreaView } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import AsyncStorage from '@react-native-async-storage/async-storage';
import * as DocumentPicker from 'expo-document-picker';
import { useFonts } from 'expo-font';
import {BricolageGrotesque_600SemiBold} from '@expo-google-fonts/bricolage-grotesque/600SemiBold';
import {BricolageGrotesque_700Bold} from '@expo-google-fonts/bricolage-grotesque/700Bold';
import {BricolageGrotesque_800ExtraBold} from '@expo-google-fonts/bricolage-grotesque/800ExtraBold';
import {SourceSans3_400Regular} from '@expo-google-fonts/source-sans-3/400Regular';
import {SourceSans3_600SemiBold} from '@expo-google-fonts/source-sans-3/600SemiBold';
import {SourceSans3_700Bold} from '@expo-google-fonts/source-sans-3/700Bold';
import {SourceSerif4_400Regular_Italic} from '@expo-google-fonts/source-serif-4/400Regular_Italic';
import {createTheme,font,typography,radius} from './theme/tokens';
import {CiteMark} from './components/CiteMark';

function Text(props: TextProps) {
  return <NativeText maxFontSizeMultiplier={1.35} {...props}
    style={[{fontFamily:font.body}, props.style]} />;
}

type IconName = React.ComponentProps<typeof Ionicons>['name'];
type Tab = 'Home' | 'Library' | 'Learn' | 'Ask' | 'Settings';
type Book = { id: string; title: string; meta: string; sample: boolean };
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
  const [askShown, setAskShown] = useState(false);
  const [review, setReview] = useState<number[]>([]);
  const [startedAt, setStartedAt] = useState(0);
  const [duration, setDuration] = useState(0);
  const [extraCards,setExtraCards] = useState<typeof flashcards>([]);
  const [savedAnswer,setSavedAnswer] = useState(false);
  const { width } = useWindowDimensions();
  const c = createTheme(dark);
  const s = styles(c);
  const icon = (name: IconName, size = 22, color = c.text) => <Ionicons name={name} size={size} color={color} />;
  useEffect(() => {
    AsyncStorage.getItem('citecoach-preview-style').then((raw) => {
      if (!raw) return;
      try { const v = JSON.parse(raw); setDark(v.dark === true); } catch {}
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
  const saveStyle = (d: boolean) => { setDark(d); AsyncStorage.setItem('citecoach-preview-style', JSON.stringify({dark:d})).catch(() => {}); };
  const start = () => { setStartedAt(Date.now()); Keyboard.dismiss(); setSession(true); setIndex(0); setChoice(null); setChecked(false); setAnswers([]); setFinished(false); setReveal(false); setKnown([]); };
  const openLearn = (next: 'Quiz' | 'Flashcards') => { setMode(next); setSession(false); navigate('Learn'); };
  const button = (label: string, onPress: () => void, name?: IconName, testID?: string, disabled = false) => (
    <Pressable testID={testID} accessibilityRole="button" accessibilityLabel={label} disabled={disabled}
      onPress={onPress} style={({pressed}) => [s.primary, disabled && {opacity: .42}, pressed && {opacity: .8}]}>
      {name && icon(name, 20, c.buttonInk)}<Text style={s.primaryText}>{label}</Text>
    </Pressable>
  );
  const citation = (page:number, text:string) => <Pressable testID={'citation-' + page} accessibilityRole="button"
    accessibilityLabel={'Open sample source page ' + page} onPress={() => {setSource({page,text});setModal('source');}}
    style={s.citation}><Text style={s.citationText}>p. {page}</Text>{icon('open-outline',12,c.ink)}</Pressable>;
  const avatar = <Pressable testID="open-settings" accessibilityRole="button" accessibilityLabel="Open settings" onPress={() => navigate('Settings')} style={s.avatar}><Text style={{fontFamily:font.label,color:c.primary}}>P</Text></Pressable>;
  const pill = (text: string, name: IconName = 'sparkles-outline') => <View style={s.pill}>{icon(name, 14, c.ink)}<Text style={s.pillText}>{text}</Text></View>;
  const section = (title: string, action?: string, onPress?: () => void) => <View style={s.section}><Text style={s.sectionTitle}>{title}</Text>{action && <Pressable onPress={onPress}><Text style={s.link}>{action}</Text></Pressable>}</View>;
  const bookCard = (book: Book, compact = false) => (
    <Pressable key={book.id} testID={'book-' + book.id} accessibilityRole="button" onPress={() => {setActiveBook(book); setModal('book');}}
      style={({pressed}) => [s.book, pressed && {opacity: .75}]}>
      <View style={s.pdf}>{icon('document-text-outline', compact ? 26 : 30, c.amberText)}<Text style={s.pdfText}>PDF</Text></View>
      <View style={{flex: 1, gap: 6}}><Text style={s.bookTitle}>{book.title}</Text><Text style={s.small}>{book.meta}</Text>{book.sample && <View style={s.track}><View style={[s.fill,{width:book.id === 'ml' ? '40%' : '12%'}]}/></View>}</View>
      {icon('chevron-forward', 20, c.muted)}
    </Pressable>
  );
  const importPdf = async () => {
    try {
      setImportError('');
      const result = await DocumentPicker.getDocumentAsync({type: ['application/pdf','application/epub+zip'], copyToCacheDirectory: true});
      if (!result.canceled) {
        const file = result.assets[0];
        setBooks((previous) => [...previous, {id: String(Date.now()), title: file.name, meta: 'Imported file · UI preview', sample: false}]);
      }
    } catch { setImportError('Could not open the PDF picker. Please try again.'); }
  };
  const header = (title: string, subtitle: string) => <View style={{gap: 8}}><Text style={s.heading}>{title}</Text><Text style={s.body}>{subtitle}</Text></View>;
  const home = (
    <>
      <View style={s.top}><View style={{flexDirection:'row',alignItems:'center',gap:8}}><CiteMark/><Text style={s.brand}>CiteCoach</Text></View>{avatar}</View>
      <Text style={s.eyebrow}>{new Date().toLocaleDateString('en',{weekday:'long',day:'numeric',month:'long'}).toUpperCase()}</Text>
      <Text style={s.hero}>Pick up where{'\n'}you left off.</Text>
      <Text style={s.small}>A sample study session · UI preview</Text>
      <Pressable accessibilityRole="button" onPress={() => {setActiveBook(sampleBooks[0]);setModal('book');}} style={s.continueCard}>
        <Text style={s.heroEyebrow}>CONTINUE · CHAPTER 2 OF 9</Text>
        <Text style={s.continueTitle}>Classification</Text>
        <Text style={s.heroBody}>Introduction to Machine Learning</Text>
        <View style={s.heroTrack}><View style={s.heroFill}/></View>
        <View style={s.progressRow}><View style={s.continueButton}><Text style={s.continueLabel}>Continue</Text>{icon('arrow-forward',18,'#1F4D3A')}</View><Text style={s.heroBody}>Sample chapter</Text></View>
      </Pressable>
      <View style={{flexDirection:width < 350 ? 'column':'row',gap:14}}>
        <Pressable testID="quick-Ask" onPress={() => navigate('Ask')} style={[s.shortcut,{flex:width < 350 ? undefined:1,backgroundColor:c.pale}]}>{icon('chatbubble-ellipses-outline',24,c.ink)}<Text style={s.bookTitle}>Ask a question</Text><Text style={s.small}>Answers cite the page</Text></Pressable>
        <Pressable testID="quick-Quiz" onPress={() => openLearn('Quiz')} style={[s.shortcut,{flex:width < 350 ? undefined:1,backgroundColor:c.practice}]}>{icon('checkbox-outline',24,c.text)}<Text style={s.bookTitle}>Quick quiz</Text><Text style={s.small}>3 sample questions</Text></Pressable>
      </View>
      <Pressable testID="home-review" onPress={() => openLearn('Flashcards')} style={s.reviewRow}>
        {icon('albums-outline',22,c.primary)}<View style={{flex:1,gap:4}}><Text style={s.bookTitle}>{review.length ? review.length + ' cards in review':'Nothing to review yet'}</Text><Text style={s.small}>{review.length ? 'From your sample quiz':'Missed sample questions will appear here'}</Text></View><Text style={s.link}>Review</Text>
      </Pressable>
      {section('Recently opened','Your books',() => navigate('Library'))}
      {bookCard(sampleBooks[0],true)}
    </>
  );
  const library = (
    <>
      <View style={s.top}><Text style={s.heading}>Your books</Text>{avatar}</View><Text style={s.small}>Sample books and your imported PDFs</Text>
      <View style={s.search}>{icon('search-outline', 20, c.muted)}<TextInput testID="library-search" accessibilityLabel="Search books" placeholder="Search your books" placeholderTextColor={c.muted} value={search} onChangeText={setSearch} style={[s.inputText, {flex: 1}]} /></View>
      <View style={s.chips}>{['All books', 'In progress', 'Finished'].map((f) => <Pressable key={f} onPress={() => setFilter(f)} style={[s.chip, filter === f && s.chipActive]}><Text style={[s.chipText, filter === f && {color: c.buttonInk}]}>{f}</Text></Pressable>)}</View>
      {section(String(books.length) + ' books', 'PDF collection')}
      {(filter === 'Finished' ? [] : filter === 'In progress' ? books.filter(b => b.sample) : books).filter((b) => b.title.toLowerCase().includes(search.toLowerCase())).map((b) => bookCard(b))}
      {books.filter((b) => b.title.toLowerCase().includes(search.toLowerCase())).length === 0 && <View style={s.empty}>{icon('search-outline', 32, c.muted)}<Text style={s.bookTitle}>No matching books</Text><Text style={s.small}>Try a different title.</Text></View>}
      {importError ? <Text accessibilityRole="alert" style={{color: '#B23C32'}}>{importError}</Text> : null}
      {button('Import a PDF', importPdf, 'add-outline', 'import-pdf')}<Text style={s.small}>Files you import stay on this device. PDF processing is not connected in this preview.</Text>
    </>
  );
  const current = questions[index];
  const cards = [...flashcards,...extraCards];
  const currentCard = cards[index];
  const score = answers.filter((value, i) => value === questions[i].answer).length;
  const learn = (
    <>
      <View style={s.top}><Text style={s.heading}>Learn</Text>{avatar}</View><Text style={s.body}>Practise a chapter or review a card.</Text>
      <View style={s.segments}>{(['Quiz','Flashcards'] as const).map((m) => <Pressable key={m} testID={'mode-' + m} onPress={() => {setMode(m); setSession(false);}} style={[s.segment, mode === m && {backgroundColor: c.primary}]}><Text style={[s.segmentText, mode === m && {color: c.buttonInk}]}>{m}</Text></Pressable>)}</View>
      {!session ? <>
        <View style={s.card}>
          <Text style={s.fieldLabel}>STUDY BOOK</Text><Text style={s.bookTitle}>Introduction to Machine Learning</Text>
          <View style={s.divider} />
          <Text style={s.fieldLabel}>CHAPTER</Text>
          <Pressable testID="choose-chapter" onPress={() => setModal('chapter')} style={s.select}><Text style={[s.body, {flex: 1, color: c.text}]}>{chapter}</Text>{icon('chevron-down', 20, c.muted)}</Pressable>
          <Text style={s.fieldLabel}>TOPIC</Text><TextInput accessibilityLabel="Study topic" value={topic} onChangeText={setTopic} placeholder="What would you like to study?" placeholderTextColor={c.muted} style={s.textField} />
        </View>
        <View style={s.note}>{icon('information-circle-outline', 20, c.muted)}<Text style={[s.small, {flex: 1}]}>Try the study flow with sample questions. Live generation is not connected in this preview.</Text></View>
        {button(mode === 'Quiz' ? 'Try sample quiz' : 'Try sample flashcards', start, 'play-outline', 'start-session')}
      </> : mode === 'Quiz' ? finished ? <>
        <View style={[s.card, {alignItems: 'center', gap: 18, paddingVertical: 32}]}>
          
          <Text style={s.heading}>{score >= 2 ? 'Good session.' : 'Session done.'}</Text><View style={{width:120,height:120,borderRadius:60,borderWidth:5,borderColor:c.accent,alignItems:'center',justifyContent:'center'}}><Text testID="quiz-score" style={{fontFamily:font.display,fontSize:38,lineHeight:46,color:c.primary}}>{score} / {questions.length}</Text><Text style={s.small}>correct</Text></View>
          <Text style={[s.body, {textAlign: 'center'}]}>Sample quiz · {duration} seconds</Text>
        </View>
        {review.length > 0 && <View style={s.card}><Text style={s.eyebrow}>WORTH ANOTHER LOOK</Text>{review.map(i => <View key={i} style={{gap:8}}><Text style={s.body}>{questions[i].q}</Text>{citation(questions[i].page,questions[i].explanation)}</View>)}<Text style={s.small}>{review.length} cards added to sample review</Text></View>}{button('Retake sample quiz', start, 'refresh-outline')}
        <Pressable onPress={() => setSession(false)} style={s.outline}><Text style={s.link}>Choose another chapter</Text></Pressable>
      </> : <>
        <View style={s.progressRow}><Text style={s.link}>Question {index + 1} of {questions.length}</Text><Text style={s.small}>Sample quiz</Text></View>
        <View style={s.segmentProgress}>{questions.map((_,i) => <View key={i} style={[s.progressSegment,{backgroundColor:i < index ? c.primary : i === index ? c.accent:c.border}]}/>)}</View>
        <Text style={s.question}>{current.q}</Text>
        <View style={{gap: 12}}>{current.options.map((option, i) => <Pressable key={option} testID={'answer-' + i} disabled={checked} accessibilityRole="button" accessibilityState={{selected: choice === i}}
          onPress={() => setChoice(i)} style={[s.option, choice === i && {borderColor: c.primary, backgroundColor: c.pale}, checked && i === current.answer && {borderColor: c.primary, backgroundColor: c.pale}, checked && i === choice && i !== current.answer && {borderColor:c.danger,backgroundColor:c.dangerBg}, checked && i !== current.answer && i !== choice && {opacity:.55}]}>
          <View style={[s.letter, choice === i && {backgroundColor:checked && i !== current.answer ? c.danger:c.primary}]}><Text style={{fontWeight: '700', color: choice === i ? (c.buttonInk) : c.ink}}>{'ABCD'[i]}</Text></View>
          <Text style={[s.body, {flex: 1, color: c.text}]}>{option}</Text>
          {checked && i === current.answer && icon('checkmark-circle', 22, c.primary)}{checked && i === choice && i !== current.answer && icon('close-circle',22,c.danger)}
        </Pressable>)}</View>
        {checked ? <View style={[s.card, {backgroundColor:choice === current.answer ? c.pale:c.dangerBg}]}><Text testID="answer-feedback" style={[s.bookTitle, {color: c.ink}]}>{choice === current.answer ? 'Correct.' : 'Not quite.'}</Text><Text style={[s.body, {color: c.ink}]}>{current.explanation}</Text>{citation(current.page,current.explanation)}</View> : null}
        {button(checked ? (index === questions.length - 1 ? 'See my results' : 'Next question') : 'Check answer', () => {
          if (!checked) {setAnswers((previous) => [...previous, choice!]); if(choice !== current.answer) setReview(previous => previous.includes(index)?previous:[...previous,index]); setChecked(true);}
          else if (index === questions.length - 1) {setDuration(Math.max(1,Math.round((Date.now()-startedAt)/1000)));setFinished(true);}
          else {setIndex(index + 1); setChoice(null); setChecked(false);}
        }, checked ? 'arrow-forward-outline' : 'checkmark-outline', 'quiz-action', !checked && choice === null)}
        {!checked && <Pressable onPress={() => {setSource({page:current.page,text:current.explanation});setModal('source');}} style={{alignItems:'center',padding:8}}><Text style={s.link}>Don't know? Show me the page</Text></Pressable>}
      </> : <>
        <View style={s.progressRow}><Text style={s.link}>Card {index + 1} of {cards.length}</Text><Text style={s.small}>{known.length} remembered</Text></View>
        <View style={[s.card, {paddingVertical: 30, minHeight: 240, justifyContent: 'center'}]}>
          {pill('Sample flashcard', 'albums-outline')}<Text style={s.question}>{currentCard.q}</Text>
          {reveal ? <><View style={s.divider} /><Text style={s.body}>{currentCard.a}</Text><Pressable onPress={() => {setSource({page: currentCard.page, text: currentCard.a}); setModal('source');}}><Text style={s.link}>View sample source · page {currentCard.page}</Text></Pressable></> : <Pressable onPress={() => setReveal(true)} style={s.outline}><Text style={s.link}>Reveal answer</Text></Pressable>}
        </View>
        {reveal && button(known.includes(index) ? 'Remembered' : 'I remembered this', () => setKnown((previous) => previous.includes(index) ? previous : [...previous, index]), 'checkmark-circle-outline')}
        {button(index === cards.length - 1 ? 'Start again' : 'Next card', () => {setIndex((index + 1) % cards.length); setReveal(false);}, 'arrow-forward-outline')}
      </>}
    </>
  );
  const emptyLibrary = <>
    <View style={s.top}><View style={{flexDirection:'row',gap:8,alignItems:'center'}}><CiteMark/><Text style={s.brand}>CiteCoach</Text></View>{avatar}</View>
    <View style={{minHeight:260,justifyContent:'center',gap:16,paddingVertical:32}}>
      <Text style={s.hero}>Start with one book.</Text>
      <Text style={s.body}>Import a PDF or EPUB, or try the sample book to explore the study flow.</Text>
      <Text style={s.small}>Files you import stay on this device.</Text>
    </View>
    {button('Import a PDF',importPdf,'add-outline','empty-import')}
    <Pressable testID="try-sample-book" onPress={() => {setBooks(sampleBooks);navigate('Home');}} style={s.outline}><Text style={s.link}>Try the sample book instead</Text></Pressable>
    <Text style={s.small}>Live book processing and offline answers are not connected in this UI preview.</Text>
  </>;
  const ask = (
    <>
      <View style={s.top}><Text style={s.heading}>Ask</Text>{avatar}</View>
      <Text style={s.small}>Sample discussion · Introduction to Machine Learning</Text>
      <View style={s.askScope}>{icon('book-outline',18,c.primary)}<Text style={[s.bookTitle,{flex:1}]}>Introduction to Machine Learning</Text>{pill('Sample book','document-text-outline')}</View>
      {askShown ? <>
        <View style={s.userBubble}><Text style={s.body}>{question || 'What is supervised learning?'}</Text></View>
        <View style={s.coachBubble}>
          <View style={{flexDirection:'row',alignItems:'center',gap:8}}><CiteMark size={24}/><Text style={s.eyebrow}>COACH · SAMPLE BOOK</Text></View>
          <Text style={s.body}>Supervised learning trains on labelled examples, where the correct answer is already known.</Text>
          {citation(12,questions[0].explanation)}
          <Text style={s.body}>Unsupervised learning uses no labels and finds structure, such as groups of similar examples.</Text>
          {citation(15,'Unsupervised learning discovers structure in unlabelled examples.')}
          <View style={s.quoteBox}><Text style={s.quote}>“The presence or absence of a target variable is the defining split.”</Text><Text style={s.small}>Sample book passage · p. 12</Text></View>
          <Pressable testID="save-answer-card" disabled={savedAnswer} onPress={() => {
            setExtraCards(previous => [...previous,{q:'How do supervised and unsupervised learning differ?',a:'Supervised learning uses labelled examples. Unsupervised learning finds structure without target labels.',page:12}]);
            setSavedAnswer(true);
          }} style={s.outline}><Text style={s.link}>{savedAnswer ? 'Added to sample flashcards':'Make a flashcard'}</Text></Pressable>
        </View>
      </> : <View style={s.card}><Text style={s.bookTitle}>Start with a question.</Text><Text style={s.body}>This preview demonstrates a cited sample response. Live offline answers are not connected yet.</Text></View>}
      <View style={s.chips}>{['Compare supervised and unsupervised learning','Explain simply','Quiz me on this'].map(label =>
        <Pressable key={label} onPress={() => {
          if(label === 'Quiz me on this') {openLearn('Quiz');return;}
          setQuestion('What is the difference between supervised and unsupervised learning?');setAskShown(true);setSavedAnswer(false);
        }} style={s.chip}><Text style={s.chipText}>{label}</Text></Pressable>)}</View>
      <View style={s.askInput}><TextInput testID="ask-input" accessibilityLabel="Ask about this book" value={question} onChangeText={value => {setQuestion(value);setAskShown(false);setSavedAnswer(false);}} placeholder="Ask about this book…" placeholderTextColor={c.placeholder}
        multiline style={[s.inputText,{flex:1,minWidth:0,maxHeight:120}]} />
        <Pressable testID="send-ask" accessibilityLabel="Show sample answer" onPress={() => {Keyboard.dismiss();setAskShown(true);setSavedAnswer(false);}} style={s.arrow}>{icon('arrow-up',22,c.buttonInk)}</Pressable>
      </View>
    </>
  );
  const settings = (
    <>
      <Pressable accessibilityLabel="Back to Home" onPress={() => navigate('Home')} style={{alignSelf:'flex-start',padding:8}}>{icon('arrow-back',24)}</Pressable>{header('Settings','Your study preferences')}
      <View style={s.card}><View style={s.progressRow}><View style={{flex: 1, gap: 5}}><Text style={s.bookTitle}>Dark appearance</Text><Text style={s.small}>A softer screen after hours</Text></View><Switch accessibilityLabel="Dark appearance" value={dark} onValueChange={(value) => saveStyle(value)} trackColor={{true: c.primary, false: c.border}} /></View></View>
      {section('Offline AI')}
      <View style={s.card}><View style={{flexDirection: 'row', gap: 12}}><View style={s.quickIcon}>{icon('hardware-chip-outline', 24, c.ink)}</View><View style={{flex: 1, gap: 7}}><Text style={s.bookTitle}>Learn from your own books.</Text><Text style={s.body}>The offline model is not connected in this UI preview.</Text></View></View></View>
      {section('About this preview')}
      <Pressable testID="empty-library-preview" onPress={() => {setBooks([]);navigate('Library');}} style={s.outline}><Text style={s.link}>Preview the empty library</Text></Pressable>
      <View style={s.card}><Text style={s.body}>Explore the layout, colors, navigation, and sample study flows. This is a separate preview app and does not replace your current CiteCoach installation.</Text></View>
      <Text style={[s.small, {textAlign: 'center', marginVertical: 12}]}>CiteCoach · Design system preview 0.2</Text>
    </>
  );
  return (
    <SafeAreaView style={{flex: 1, backgroundColor: c.bg}} edges={['top','bottom']}>
      <StatusBar barStyle={dark ? 'light-content' : 'dark-content'} backgroundColor={c.bg} />
      <KeyboardAvoidingView style={{flex: 1}} behavior={Platform.OS === 'ios' ? 'padding' : 'height'}>
        <ScrollView key={tab + String(session) + String(index)} testID="screen-scroll" style={{flex: 1}} contentContainerStyle={{padding:20, gap:14, width: '100%', maxWidth: 640, alignSelf: 'center', paddingBottom: 32}}
          keyboardShouldPersistTaps="handled" keyboardDismissMode="on-drag">
          {books.length === 0 && tab !== 'Settings' ? emptyLibrary : tab === 'Home' ? home : tab === 'Library' ? library : tab === 'Learn' ? learn : tab === 'Ask' ? ask : settings}
        </ScrollView>
        {!keyboard && tab !== 'Settings' && books.length > 0 && <View style={s.nav}>{([{tab:'Home', icon:'home-outline'},{tab:'Library',icon:'folder-open-outline'},{tab:'Learn',icon:'school-outline'},{tab:'Ask',icon:'chatbubble-ellipses-outline'}] as {tab: Tab; icon: IconName}[]).map((item) => (
          <Pressable key={item.tab} testID={'nav-' + item.tab} accessibilityRole="tab" accessibilityState={{selected: tab === item.tab}} onPress={() => navigate(item.tab)} style={s.navItem}>
            <View style={[s.navIcon, tab === item.tab && {backgroundColor:'#D7EEE1'}]}>{icon(item.icon, 23, tab === item.tab ? '#0F1F18' : '#D4DED7')}</View><Text style={[s.navLabel, tab === item.tab && {color:'#D7EEE1',fontFamily:font.label}]}>{item.tab}</Text>
          </Pressable>))}</View>}
      </KeyboardAvoidingView>
      <Modal visible={modal !== null} transparent animationType="slide" onRequestClose={() => setModal(null)}>
        <View style={s.scrim}><SafeAreaView style={[s.sheet, {maxHeight: '85%'}]} edges={['bottom']}>
          <View style={s.sheetTop}><View style={s.handle} /><Pressable accessibilityLabel="Close" testID="close-modal" onPress={() => setModal(null)} style={{padding: 10}}>{icon('close', 24)}</Pressable></View>
          <ScrollView contentContainerStyle={{paddingHorizontal: 24, paddingBottom: 28, gap: 18}} keyboardShouldPersistTaps="handled">
            {modal === 'chapter' ? <><Text style={s.heading}>Choose a chapter</Text><Text style={s.small}>Sample textbook chapters</Text>{['Whole book','Chapter 1 · Getting started','Chapter 2 · Classification','Chapter 3 · Regression'].map((value) => <Pressable key={value} testID={'chapter-' + value.split(' ')[1]} onPress={() => {setChapter(value); setModal(null); setSession(false);}} style={s.select}><Text style={[s.body, {flex: 1, color: c.text}]}>{value}</Text>{chapter === value && icon('checkmark-circle', 22, c.primary)}</Pressable>)}</> : modal === 'source' ? <><Text style={s.heading}>Sample source</Text>{pill('PDF page ' + source.page, 'document-text-outline')}<View style={[s.card, {backgroundColor: c.pale}]}><Text style={s.quote}>{source.text}</Text></View><Text style={s.small}>A sample excerpt for evaluating the citation interface.</Text></> : modal === 'ask' ? <><Text style={s.heading}>Ask your textbook</Text><Text style={s.bookTitle}>{question || 'What is supervised learning?'}</Text><View style={s.note}>{icon('information-circle-outline', 22, c.muted)}<Text style={[s.body, {flex: 1}]}>Offline AI is not connected in this UI preview. You can explore the sample quiz and flashcards.</Text></View>{button('Explore sample quiz', () => {setModal(null); openLearn('Quiz');}, 'arrow-forward-outline')}</> : <><View style={s.pdf}>{icon('document-text-outline', 30, c.amberText)}</View><Text style={s.heading}>{activeBook.title}</Text><Text style={s.body}>{activeBook.meta}</Text><Text style={s.small}>{activeBook.sample ? 'Explore the sample learning flow for this book.' : 'This PDF has been imported. Reading and AI processing are not connected in this UI preview.'}</Text>{activeBook.sample && button('Start studying', () => {setModal(null); openLearn('Quiz');}, 'school-outline')}</>}
          </ScrollView>
        </SafeAreaView></View>
      </Modal>
    </SafeAreaView>
  );
}

function styles(c:ReturnType<typeof createTheme>) { return StyleSheet.create({
  top:{flexDirection:'row',alignItems:'center',justifyContent:'space-between',gap:12},
  brand:{...typography.title,fontSize:25,lineHeight:30,color:c.text},
  avatar:{width:40,height:40,borderRadius:20,backgroundColor:c.pale,alignItems:'center',justifyContent:'center'},
  pill:{alignSelf:'flex-start',flexDirection:'row',alignItems:'center',gap:6,backgroundColor:c.pale,borderRadius:radius.chip,paddingHorizontal:10,paddingVertical:6},
  pillText:{...typography.label,fontSize:12,lineHeight:16,color:c.ink},
  eyebrow:{...typography.eyebrow,color:c.muted},
  hero:{...typography.display,color:c.text},
  heading:{...typography.title,color:c.text},
  body:{...typography.body,color:c.text},
  small:{...typography.small,color:c.muted},
  section:{flexDirection:'row',alignItems:'center',justifyContent:'space-between',gap:12,flexWrap:'wrap',marginTop:4},
  sectionTitle:{...typography.heading,color:c.text},
  link:{...typography.label,lineHeight:20,color:c.primary},
  askCard:{backgroundColor:c.pale,borderRadius:radius.hero,padding:20,gap:12},
  askInput:{flexDirection:'row',alignItems:'flex-end',gap:8,backgroundColor:c.surface,borderWidth:1,borderColor:c.border,borderRadius:radius.control,padding:8,paddingLeft:13,minHeight:48},
  inputText:{...typography.body,color:c.text,paddingVertical:6},
  arrow:{width:36,height:36,borderRadius:18,backgroundColor:c.primary,alignItems:'center',justifyContent:'center'},
  quick:{backgroundColor:c.surface,borderWidth:1,borderColor:c.border,borderRadius:radius.card,padding:16,gap:8},
  quickIcon:{width:44,height:44,borderRadius:radius.control,backgroundColor:c.pale,alignItems:'center',justifyContent:'center'},
  book:{flexDirection:'row',alignItems:'center',gap:14,backgroundColor:c.surface,borderWidth:1,borderColor:c.border,borderRadius:radius.card,padding:16},
  pdf:{width:40,minHeight:52,borderRadius:5,backgroundColor:c.amber,alignItems:'center',justifyContent:'center',gap:2,paddingVertical:5,borderLeftWidth:4,borderLeftColor:c.amberText},
  pdfText:{fontFamily:font.label,fontSize:9,lineHeight:12,color:c.amberText},
  bookTitle:{fontFamily:font.strong,fontSize:17,lineHeight:22,color:c.text},
  note:{flexDirection:'row',gap:10,alignItems:'flex-start',paddingVertical:3},
  primary:{backgroundColor:c.primary,borderRadius:radius.control,minHeight:48,padding:13,flexDirection:'row',alignItems:'center',justifyContent:'center',gap:9},
  primaryText:{...typography.label,color:c.buttonInk,fontSize:15,flexShrink:1,textAlign:'center'},
  search:{borderWidth:1,borderColor:c.border,borderRadius:radius.control,backgroundColor:c.surface,paddingHorizontal:14,paddingVertical:7,flexDirection:'row',alignItems:'center',gap:10},
  chips:{flexDirection:'row',flexWrap:'wrap',gap:8},
  chip:{paddingHorizontal:14,paddingVertical:9,borderRadius:radius.chip,borderWidth:1,borderColor:c.border,backgroundColor:c.surface},
  chipActive:{backgroundColor:c.primary,borderColor:c.primary},
  chipText:{...typography.label,color:c.muted},
  segments:{backgroundColor:c.surface,borderRadius:radius.control,padding:4,borderWidth:1,borderColor:c.border,flexDirection:'row',gap:4},
  segment:{flex:1,paddingHorizontal:10,paddingVertical:11,borderRadius:radius.chip,alignItems:'center'},
  segmentText:{...typography.label,color:c.muted},
  card:{backgroundColor:c.surface,borderWidth:1,borderColor:c.border,borderRadius:radius.card,padding:16,gap:12},
  fieldLabel:{...typography.eyebrow,color:c.muted},
  divider:{height:1,backgroundColor:c.border,marginVertical:3},
  select:{flexDirection:'row',alignItems:'center',gap:10,borderWidth:1,borderColor:c.border,borderRadius:radius.control,padding:12},
  textField:{...typography.body,borderWidth:1,borderColor:c.border,borderRadius:radius.control,padding:12,color:c.text},
  progressRow:{flexDirection:'row',alignItems:'center',justifyContent:'space-between',gap:10,flexWrap:'wrap'},
  track:{height:6,borderRadius:3,backgroundColor:c.border,overflow:'hidden'},
  fill:{height:6,borderRadius:3,backgroundColor:c.accent},
  question:{...typography.heading,color:c.text},
  option:{borderWidth:1.5,borderColor:c.border,backgroundColor:c.surface,borderRadius:radius.control,padding:12,flexDirection:'row',gap:12,alignItems:'center',minHeight:52},
  letter:{width:30,height:30,borderRadius:radius.chip,backgroundColor:c.pale,alignItems:'center',justifyContent:'center'},
  outline:{borderWidth:1,borderColor:c.border,borderRadius:radius.control,padding:12,alignItems:'center'},
  empty:{padding:24,gap:12,alignItems:'center'},
  nav:{backgroundColor:c.nav,flexDirection:'row',marginHorizontal:14,marginBottom:10,borderRadius:radius.pill,padding:6,shadowColor:'#0F1F18',shadowOffset:{width:0,height:10},shadowOpacity:.18,shadowRadius:24,elevation:7},
  navItem:{flex:1,alignItems:'center',gap:2,paddingVertical:3},
  navIcon:{paddingHorizontal:15,paddingVertical:5,borderRadius:18},
  navLabel:{fontFamily:font.body,fontSize:12,lineHeight:16,color:'#D4DED7'},
  scrim:{flex:1,backgroundColor:'rgba(15,31,24,.4)',justifyContent:'flex-end'},
  sheet:{backgroundColor:c.surface,borderTopLeftRadius:24,borderTopRightRadius:24,width:'100%',maxWidth:640,alignSelf:'center'},
  sheetTop:{padding:12,flexDirection:'row',alignItems:'center',justifyContent:'flex-end'},
  handle:{position:'absolute',top:12,left:'44%',width:44,height:4,borderRadius:2,backgroundColor:c.border},
  continueCard:{padding:20,borderRadius:radius.hero,backgroundColor:c.hero,gap:8},
  heroEyebrow:{...typography.eyebrow,color:'#D7EEE1'},
  continueTitle:{...typography.title,color:c.onHero},
  heroBody:{...typography.small,color:'#EDF4EF'},
  heroTrack:{height:6,borderRadius:3,backgroundColor:'#53745E',marginVertical:8,overflow:'hidden'},
  heroFill:{height:6,width:'40%',backgroundColor:'#F2C56A',borderRadius:3},
  continueButton:{backgroundColor:'#FFFFFF',borderRadius:radius.control,paddingHorizontal:16,paddingVertical:12,flexDirection:'row',gap:12,alignItems:'center'},
  continueLabel:{...typography.label,color:'#1F4D3A'},
  shortcut:{flex:1,minWidth:0,padding:16,borderRadius:radius.card,gap:8},
  reviewRow:{flexDirection:'row',alignItems:'center',gap:12,padding:16,borderRadius:radius.card,borderWidth:1,borderColor:c.border,backgroundColor:c.surface},
  citation:{flexDirection:'row',gap:6,alignItems:'center',alignSelf:'flex-start',backgroundColor:c.pale,paddingHorizontal:8,paddingVertical:3,borderRadius:radius.chip,minHeight:24},
  citationText:{...typography.label,fontSize:13,color:c.ink,fontVariant:['tabular-nums']},
  segmentProgress:{flexDirection:'row',gap:6},
  progressSegment:{flex:1,height:5,borderRadius:3},
  askScope:{padding:12,borderRadius:radius.control,borderWidth:1,borderColor:c.border,backgroundColor:c.surface,flexDirection:'row',gap:8,alignItems:'center',flexWrap:'wrap'},
  userBubble:{backgroundColor:c.pale,borderRadius:radius.card,padding:16,alignSelf:'flex-end',maxWidth:'92%'},
  coachBubble:{backgroundColor:c.surface,borderRadius:radius.card,padding:16,gap:12,borderWidth:1,borderColor:c.border},
  quoteBox:{borderLeftWidth:3,borderLeftColor:c.accent,paddingLeft:12,gap:8,marginVertical:4},
  quote:{...typography.quote,color:c.text},
}); }

export default function App() {
  const [loaded,error] = useFonts({
    BricolageGrotesque_600SemiBold,BricolageGrotesque_700Bold,BricolageGrotesque_800ExtraBold,
    SourceSans3_400Regular,SourceSans3_600SemiBold,SourceSans3_700Bold,SourceSerif4_400Regular_Italic,
  });
  if (!loaded && !error) return <SafeAreaProvider><SafeAreaView style={{flex:1,backgroundColor:'#F6F4EE',alignItems:'center',justifyContent:'center',gap:16}}><CiteMark size={36}/><NativeText style={{color:'#1F4D3A',fontSize:17}}>Opening CiteCoach…</NativeText></SafeAreaView></SafeAreaProvider>;
  return <SafeAreaProvider><AppBody /></SafeAreaProvider>;
}
