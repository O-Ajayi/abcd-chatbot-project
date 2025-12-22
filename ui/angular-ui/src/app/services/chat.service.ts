import { Injectable } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Observable } from 'rxjs';

export interface ChatRequest {
  botId: string;
  botAliasId: string;
  localeId: string;
  sessionId: string;
  text: string;
  region: string;
}

export interface ChatResponse {
  messages?: Array<{ content: string }>;
  message?: string;
  sessionId?: string;
}

@Injectable({
  providedIn: 'root'
})
export class ChatService {
  private apiUrl = 'http://localhost:3000/api'; // Backend proxy URL

  constructor(private http: HttpClient) {}

  sendMessage(request: ChatRequest): Observable<ChatResponse> {
    const headers = new HttpHeaders({
      'Content-Type': 'application/json'
    });

    return this.http.post<ChatResponse>(`${this.apiUrl}/chat`, request, { headers });
  }
}

