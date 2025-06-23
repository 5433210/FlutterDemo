// HarmonyOS主要Ability实现
// 注意：实际使用时需要在HarmonyOS开发环境中运行

// 临时解决方案：使用类型声明避免编译错误
declare class Ability {
  onCreate(want: any, launchParam: any): void;
  onDestroy(): void;
  onWindowStageCreate(windowStage: any): void;
  onWindowStageDestroy(): void;
  onForeground(): void;
  onBackground(): void;
}

declare namespace Window {
  interface WindowStage {
    loadContent(page: string, callback: (err: any, data: any) => void): void;
  }
}

// 如果在HarmonyOS开发环境中，请使用以下导入：
// import Ability from '@ohos.app.ability.UIAbility';
// import Window from '@ohos.window';

export default class MainAbility extends Ability {
  onCreate(want, launchParam): void {
    console.log('[Demo] MainAbility onCreate');
  }

  onDestroy(): void {
    console.log('[Demo] MainAbility onDestroy');
  }

  onWindowStageCreate(windowStage: Window.WindowStage): void {
    console.log('[Demo] MainAbility onWindowStageCreate');
    
    windowStage.loadContent('pages/Index', (err, data) => {
      if (err.code) {
        console.error('[Demo] Failed to load the content. Cause: %{public}s', JSON.stringify(err) ?? '');
        return;
      }
      console.info('[Demo] Succeeded in loading the content. Data: %{public}s', JSON.stringify(data) ?? '');
    });
  }

  onWindowStageDestroy(): void {
    console.log('[Demo] MainAbility onWindowStageDestroy');
  }

  onForeground(): void {
    console.log('[Demo] MainAbility onForeground');
  }

  onBackground(): void {
    console.log('[Demo] MainAbility onBackground');
  }
} 