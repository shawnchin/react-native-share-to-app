import { AppState, Linking, NativeModules, Platform } from 'react-native';
import type {
  IShareToApp,
  IReturnData,
  ISharedMediaIOS,
} from './ShareToApp.interfaces';

const { ShareToApp } = NativeModules;

class ShareToAppModule implements IShareToApp {
  private isIos: boolean = Platform.OS === 'ios';
  private isClear: boolean = false;

  subscribeToSharedFiles(
    handler: Function,
    errorHandler: Function,
    protocol: string = 'ShareMedia'
  ) {
    if (this.isIos) {
      Linking.getInitialURL()
        .then((res: any) => {
          if (res && res.startsWith(`${protocol}://dataUrl`) && !this.isClear) {
            this.getFileNames(handler, errorHandler, res);
          }
        })
        .catch(() => {});
      Linking.addEventListener('url', (res: any) => {
        const url = res ? res.url : '';
        if (url.startsWith(`${protocol}://dataUrl`) && !this.isClear) {
          this.getFileNames(handler, errorHandler, res.url);
        }
      });
    } else {
      AppState.addEventListener('change', (status: string) => {
        if (status === 'active' && !this.isClear) {
          this.getFileNames(handler, errorHandler, '');
        }
      });
      if (!this.isClear) this.getFileNames(handler, errorHandler, '');
    }
  }

  clearReceivedFiles() {
    this.isClear = true;
  }

  protected getFileNames(
    handler: Function,
    errorHandler: Function,
    url: string
  ) {
    if (this.isIos) {
      ShareToApp.getFileNames(url)
        .then((data: string) => {
          let files = this.parseIosPayload(data);
          handler(files);
        })
        .catch((e: any) => errorHandler(e));
    } else {
      ShareToApp.getFileNames()
        .then((fileObject: any) => {
          let files = Object.keys(fileObject).map((k) => fileObject[k]);
          handler(files);
        })
        .catch((e: any) => errorHandler(e));
    }
  }

  private parseIosPayload(data: string): Array<IReturnData> {
    const defaults: IReturnData = {
      filePath: null,
      fileName: null,
      mimeType: null, // we don't have this info for IOS, so always null
      text: null,
      weblink: null,
    };
    const file = data;
    if (file.startsWith('text:')) {
      const text = file.replace('text:', '');
      if (this.isHttpUrl(text)) {
        return [{ ...defaults, weblink: text }];
      } else {
        return [{ ...defaults, text: text }];
      }
    } else if (file.startsWith('webUrl:')) {
      const weblink: string = file.replace('webUrl:', '');
      return [{ ...defaults, weblink: weblink }];
    } else {
      try {
        const files = JSON.parse(file) as ISharedMediaIOS[];
        return files.map((f) => ({
          ...defaults,
          fileName: f.fileName || this.getFileNameFromPath(f.path),
          filePath: f.path,
        }));
      } catch (error) {
        return [{ ...defaults }];
      }
    }
  }

  private isHttpUrl(text: string): boolean {
    if (!text.startsWith('http')) {
      return false;
    }

    try {
      let url = new URL(text); // throws if not URL
      return url.protocol === 'http:' || url.protocol === 'https:';
    } catch (_) {
      return false;
    }
  }

  private getFileNameFromPath(file: string): string {
    return file.replace(/^.*[\\/:]/, '');
  }
}

export default ShareToAppModule;
