export interface IShareToApp {
    subscribeToSharedFiles(handler: Function, errorHandler: Function, protocol: string): void;
}
export interface IReturnData {
    filePath?: any | string;
    text?: any | string;
    weblink?: any | string;
    contentUri?: any | string;
    fileName?: any | string;
}
export interface ISharedMediaIOS {
    path: string;
    fileName: string;
    type: 'image' | 'video' | 'file';
}
//# sourceMappingURL=ShareToApp.interfaces.d.ts.map