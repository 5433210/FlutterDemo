// HarmonyOS构建配置文件
// 注意：实际使用时需要安装 @ohos/hvigor-ohos-plugin 依赖

// 临时解决方案：使用类型声明避免编译错误
declare const appTasks: any;

// 如果安装了正确的依赖，请使用以下导入：
// import { appTasks } from '@ohos/hvigor-ohos-plugin';

export default {
  system: appTasks || {},  /* Built-in plugin of Hvigor. It cannot be modified. */
  plugins:[]               /* Custom plugin to extend the functionality of Hvigor. */
} 