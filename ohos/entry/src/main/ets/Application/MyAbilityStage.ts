// HarmonyOS应用生命周期管理
// 注意：实际使用时需要在HarmonyOS开发环境中运行

// 临时解决方案：使用类型声明避免编译错误
declare class AbilityStage {
  onCreate(): void;
}

// 如果在HarmonyOS开发环境中，请使用以下导入：
// import AbilityStage from '@ohos.app.ability.AbilityStage';

export default class MyAbilityStage extends AbilityStage {
  onCreate(): void {
    console.log('[Demo] MyAbilityStage onCreate');
  }
} 