export type PageText={page:number;text:string;label?:string};
export type LocalBook={id:string;title:string;uri:string;pages:PageText[];importedAt:number;format?:string};
export type SourceChunk={page:number;text:string;score:number;label?:string};
export type StudyCard={q:string;a:string;page:number};
export type QuizQuestion={q:string;options:string[];answer:number;explanation:string;page:number};
export type SavedStudy={bookId:string;cards:StudyCard[];quiz:QuizQuestion[]};
