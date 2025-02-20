import type { IReceiveSharingIntent } from './ReceiveSharingIntent.interfaces';
declare class ReceiveSharingIntentModule implements IReceiveSharingIntent {
    private isIos;
    private isClear;
    subscribeToSharedFiles(handler: Function, errorHandler: Function, protocol?: string): void;
    clearReceivedFiles(): void;
    protected getFileNames(handler: Function, errorHandler: Function, url: string): void;
    private parseIosPayload;
    private isHttpUrl;
    private getFileNameFromPath;
}
export default ReceiveSharingIntentModule;
//# sourceMappingURL=ReceiveSharingIntent.d.ts.map