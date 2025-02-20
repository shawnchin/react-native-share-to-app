"use strict";

import { AppState, Linking, NativeModules, Platform } from 'react-native';
const {
  ReceiveSharingIntent
} = NativeModules;
class ReceiveSharingIntentModule {
  isIos = Platform.OS === 'ios';
  isClear = false;
  subscribeToSharedFiles(handler, errorHandler, protocol = 'ShareMedia') {
    if (this.isIos) {
      Linking.getInitialURL().then(res => {
        if (res && res.startsWith(`${protocol}://dataUrl`) && !this.isClear) {
          this.getFileNames(handler, errorHandler, res);
        }
      }).catch(() => {});
      Linking.addEventListener('url', res => {
        const url = res ? res.url : '';
        if (url.startsWith(`${protocol}://dataUrl`) && !this.isClear) {
          this.getFileNames(handler, errorHandler, res.url);
        }
      });
    } else {
      AppState.addEventListener('change', status => {
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
  getFileNames(handler, errorHandler, url) {
    if (this.isIos) {
      ReceiveSharingIntent.getFileNames(url).then(data => {
        let files = this.parseIosPayload(data);
        handler(files);
      }).catch(e => errorHandler(e));
    } else {
      ReceiveSharingIntent.getFileNames().then(fileObject => {
        let files = Object.keys(fileObject).map(k => fileObject[k]);
        handler(files);
      }).catch(e => errorHandler(e));
    }
  }
  parseIosPayload(data) {
    const defaults = {
      filePath: null,
      text: null,
      weblink: null,
      contentUri: null,
      fileName: null
    };
    const file = data;
    if (file.startsWith('text:')) {
      const text = file.replace('text:', '');
      if (this.isHttpUrl(text)) {
        return [{
          ...defaults,
          weblink: text
        }];
      } else {
        return [{
          ...defaults,
          text: text
        }];
      }
    } else if (file.startsWith('webUrl:')) {
      const weblink = file.replace('webUrl:', '');
      return [{
        ...defaults,
        weblink: weblink
      }];
    } else {
      try {
        const files = JSON.parse(file);
        return files.map(f => ({
          ...defaults,
          fileName: f.fileName || this.getFileNameFromPath(f.path),
          filePath: f.path
        }));
      } catch (error) {
        return [{
          ...defaults
        }];
      }
    }
  }
  isHttpUrl(text) {
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
  getFileNameFromPath(file) {
    return file.replace(/^.*[\\/:]/, '');
  }
}
export default ReceiveSharingIntentModule;
//# sourceMappingURL=ReceiveSharingIntent.js.map