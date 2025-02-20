import type { IShareToApp } from './ShareToApp.interfaces';
declare class ShareToAppModule implements IShareToApp {
    private isIos;
    private isClear;
    subscribeToSharedFiles(handler: Function, errorHandler: Function, protocol?: string): void;
    clearReceivedFiles(): void;
    protected getFileNames(handler: Function, errorHandler: Function, url: string): void;
    private parseIosPayload;
    private isHttpUrl;
    private getFileNameFromPath;
}
export default ShareToAppModule;
//# sourceMappingURL=ShareToApp.d.ts.map