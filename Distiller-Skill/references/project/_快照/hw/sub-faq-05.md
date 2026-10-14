# 5. 权限索取行为

* 重点整治APP安装、运行和使用相关功能时，非服务所必需或无合理应用场景下，用户拒绝相关授权申请后，应用自动退出或关闭的行为。重点整治短时长、高频次，在用户明确拒绝权限申请后，频繁弹窗、反复申请与当前服务场景无关权限的行为。重点整治未及时明确告知用户索取权限的目的和用途，提前申请超出其业务功能等权限的行为。
* 用户拒绝相关授权申请后，不得强制退出或者关闭APP，不得提前申请超出其业务功能或者服务外的权限，不得利用频繁弹窗反复申请与当前服务场景无关的权限。

## **5.1 不给权限APP退出或关闭**

APP运行时，向用户索取电话、通讯录、定位、短信、录音、相机、存储、日历等权限，用户拒绝授权后，APP不应退出或关闭。

## **5.2 不给权限APP弹窗循环**

APP运行时，向用户索取权限，用户拒绝授权后，APP不应循环弹窗申请权限，使用户无法继续使用。

## **5.3 不给权限无法注册登录**

用户注册登录时，APP向用户索取权限，用户拒绝授权后，APP不应无法正常注册或登录。

![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/90/v3/CM4ky7B-Tkee6HWGG1lu7Q/zh-cn_image_0000002769149259.png?HW-CC-KV=V1&HW-CC-Date=20261009T022900Z&HW-CC-Expire=31536000000&HW-CC-Sign=1436584274704104472C8CBD40CCD8B01CA477631121BB094DC67EC456EE0CD5 "点击放大")

## **5.4 频繁申请权限**

APP运行时，在用户明确拒绝权限申请后，不应向用户频繁弹窗申请与当前服务场景无关的权限，影响用户正常使用。APP重新运行时，也不应向用户频繁弹窗申请开启与当前服务场景无关的权限。

![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/c7/v3/4mwBqGRQRYSijxs-EOvbNA/zh-cn_image_0000002514857224.gif?HW-CC-KV=V1&HW-CC-Date=20261009T022900Z&HW-CC-Expire=31536000000&HW-CC-Sign=E3401231C0C30203410B0648DDB6B1527A2441173AD215E7640B4212E11624F4 "点击放大")

## **5.5 过度申请权限**

APP首次打开或运行中，未见使用权限对应的相关功能或服务时，不应提前向用户弹窗申请开启权限。

![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/8d/v3/D7etDtWoSryte80ENLVgug/zh-cn_image_0000002739590838.png?HW-CC-KV=V1&HW-CC-Date=20261009T022900Z&HW-CC-Expire=31536000000&HW-CC-Sign=1CE6A9AF0507BD92FA55222BEF973359BB3ECAAAC89F36D87F549C3C156DA324 "点击放大")

![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/1d/v3/yhTyIocqRnCxuLXWHTKnRQ/zh-cn_image_0000002769150569.png?HW-CC-KV=V1&HW-CC-Date=20261009T022900Z&HW-CC-Expire=31536000000&HW-CC-Sign=FE836362E4B9E41E1A140DAF767C7956DF555E5A333B19ABA2578A5B59E7899C "点击放大")

![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/72/v3/sd86v3yJQLysMym79oTCLQ/zh-cn_image_0000002769030801.png?HW-CC-KV=V1&HW-CC-Date=20261009T022900Z&HW-CC-Expire=31536000000&HW-CC-Sign=AC3059136009087714F733857CF801A0FE44FC17DB76E6A87C60E6E56EF8A2CA "点击放大")

![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/83/v3/v0gBN-0JTYSPdW8D7PIjMg/zh-cn_image_0000002769030875.png?HW-CC-KV=V1&HW-CC-Date=20261009T022900Z&HW-CC-Expire=31536000000&HW-CC-Sign=8E1B1C7B34DD86C2F1350880BC98452EADDA3096B28EB3A88E1BE25C766B3D62 "点击放大")

## **5.6 申请无关权限**

APP未见提供相关业务功能或服务，不应申请通讯录、定位、短信、录音、相机、日历等权限。

![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/15/v3/Oo6z0ip8SN-JeJLz2q2OXA/zh-cn_image_0000002769151427.png?HW-CC-KV=V1&HW-CC-Date=20261009T022900Z&HW-CC-Expire=31536000000&HW-CC-Sign=B50A4C784E97DA83605DFA1C3B687714F79850B96691ACF23D323A95ACCC1066 "点击放大")

## 5.7 未同步告知权限申请的目的

APP 向用户索取敏感权限时，应同步告知用户申请该权限的目的。

敏感权限：电话、通讯录、定位、短信、麦克风（录音）、相机、存储、日历、身体传感器、通话记录、健康运动等；

同步告知：**需在应用内，权限弹窗申请的同时**，告知权限申请的使用目的。

**如下示例图适用于HarmonyOS 5.0以下的系统版本**

![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/23/v3/DDVtTa0VQtOCSi3IcWbJnA/zh-cn_image_0000002739592924.png?HW-CC-KV=V1&HW-CC-Date=20261009T022900Z&HW-CC-Expire=31536000000&HW-CC-Sign=2C22F8C8EE322F9E5CF501E6EDADD62DED3B50E69D4DDD87556E527F0D0CCBE0 "点击放大")

![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/57/v3/BztATcB9SLiKUkkrqwhS4w/zh-cn_image_0000002739593096.png?HW-CC-KV=V1&HW-CC-Date=20261009T022900Z&HW-CC-Expire=31536000000&HW-CC-Sign=08B0727AF06C78904DEBC32FE13ACE06077C261EAF23763C0DCDAE266C8B75BE "点击放大")

**如下示例图适用于HarmonyOS 5.0及以上的系统版本**

![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/92/v3/zWMbsBtzQcenL-GqYjk0RA/zh-cn_image_0000002739433396.png?HW-CC-KV=V1&HW-CC-Date=20261009T022900Z&HW-CC-Expire=31536000000&HW-CC-Sign=C9C83A98DD1728A7CFF9D5D605259EFC4745442524F5F39B05F8C3776D4266C7 "点击放大")

![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/5a/v3/_Z_4JZfrRne6BAR4GNJhFA/zh-cn_image_0000002739433470.png?HW-CC-KV=V1&HW-CC-Date=20261009T022900Z&HW-CC-Expire=31536000000&HW-CC-Sign=2394221A8601441E9CDCC773D6DB51743A4E874F9330664E03A5006BF7106F0C "点击放大")
> 说明
>
> HarmonyOS 5.0及以上已开放系统权限弹窗编辑功能，请参考[reason字段的内容写作规范](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/declare-permissions#reason字段的内容写作规范及建议)及建议填写。

