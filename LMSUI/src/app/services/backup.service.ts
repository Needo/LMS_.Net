import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

export interface BackupFile {
  fileName: string;
  filePath: string;
  fileSize: number;
  createdDate: Date;
  formattedSize: string;
}

export interface BackupResponse {
  success: boolean;
  message: string;
  fileName?: string;
  filePath?: string;
  fileSize?: number;
  timestamp?: string;
}

@Injectable({ providedIn: 'root' })
export class BackupService {
  private apiUrl = 'http://localhost:5000/api/backup';

  constructor(private http: HttpClient) {}

  createBackup(): Observable<BackupResponse> {
    return this.http.post<BackupResponse>(`${this.apiUrl}/create`, {});
  }

  listBackups(): Observable<BackupFile[]> {
    return this.http.get<BackupFile[]>(`${this.apiUrl}/list`);
  }

  restoreBackup(fileName: string): Observable<BackupResponse> {
    return this.http.post<BackupResponse>(`${this.apiUrl}/restore`, { fileName });
  }

  deleteBackup(fileName: string): Observable<BackupResponse> {
    return this.http.delete<BackupResponse>(`${this.apiUrl}/delete/${fileName}`);
  }
}
