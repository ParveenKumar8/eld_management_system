export interface ApiErrorBody {
  code: string;
  message: string;
}

export interface ApiResponse<T> {
  data: T | null;
  error: ApiErrorBody | null;
}

export function ok<T>(data: T): ApiResponse<T> {
  return { data, error: null };
}

export function fail(code: string, message: string): ApiResponse<null> {
  return { data: null, error: { code, message } };
}