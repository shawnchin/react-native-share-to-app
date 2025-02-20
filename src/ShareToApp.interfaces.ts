export interface IShareToApp {
  subscribeToSharedFiles(
    handler: Function,
    errorHandler: Function,
    protocol: string
  ): void;
}

export interface IReturnData {
  filePath?: any | string;
  fileName?: any | string;
  mimeType?: any | string;
  text?: any | string;
  weblink?: any | string;
}

export interface ISharedMediaIOS {
  path: string;
  fileName: string;
  type: 'image' | 'video' | 'file';
}
