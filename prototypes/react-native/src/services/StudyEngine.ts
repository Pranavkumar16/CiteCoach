import type {Citation,GenerationProgress} from '../domain/models';

// Integration contract only. No model is initialized or simulated here.
export type StudyRequest = {
  bookId:string;
  chapterId?:string;
  topic:string;
};
export type CitedAnswer = {text:string;citations:Citation[]};
export type GenerationOptions = {
  signal?:AbortSignal;
  onProgress?:(progress:GenerationProgress)=>void;
};
export interface StudyEngine {
  initialize(options?:GenerationOptions):Promise<void>;
  answer(request:StudyRequest & {question:string},options?:GenerationOptions):Promise<CitedAnswer>;
  dispose():Promise<void>;
}
