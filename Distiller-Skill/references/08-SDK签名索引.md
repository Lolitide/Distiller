<!-- 生成物：由 tools\build-references.ps1 产出，勿手改 -->

# 08 · SDK 签名索引

行号取自本机 SDK 头文件，可直接回到 DevEco 核对。

> [!warning] 行号与本机 SDK 版本绑定
> 这份索引是拿**生成它的那台机器**上的 SDK 生成的。团队成员换了机器或换了 SDK 版本，**行号会漂**。
> 换机器后请自己重跑一条命令刷新本文件：
>
> ```powershell
> powershell -NoProfile -ExecutionPolicy Bypass -File tools\build-references.ps1 -Only sdk -Apply
> ```
>
> **签名本身**（参数、枚举成员、`@since`）跨版本稳定，可以放心引用；只有 `L<行号>` 需要重新核对。

SDK 根：`D:\Coding\DevEco\DevEco Studio beta\DevEco Studio\sdk\default`

## Part 1 · Kit 桶导出（符号来自哪个模块）

### `hms/ets/kits/@kit.NaturalLanguageKit.d.ts`

用途：NLU Kit 桶导出

```ts
L9: import { EntityType } from '@hms.ai.nlp.textProcessing';
L10: import textProcessing from '@hms.ai.nlp.textProcessing';
L11: export { textProcessing, EntityType };
```

### `hms/ets/kits/@kit.CoreSpeechKit.d.ts`

用途：Core Speech Kit 桶导出

```ts
L9: import speechRecognizer from '@hms.ai.speechRecognizer';
L10: import textToSpeech from '@hms.ai.textToSpeech';
L11: export { speechRecognizer, textToSpeech };
```

### `hms/ets/kits/@kit.CoreVisionKit.d.ts`

用途：Core Vision Kit 桶导出

```ts
L9: import textRecognition from '@hms.ai.ocr.textRecognition';
L10: import faceDetector from '@hms.ai.face.faceDetector';
L11: import faceComparator from '@hms.ai.face.faceComparator';
L12: import subjectSegmentation from '@hms.ai.vision.subjectSegmentation';
L13: import visionBase from '@hms.ai.vision.visionBase';
L14: import objectDetection from '@hms.ai.vision.objectDetection';
L15: import skeletonDetection from '@hms.ai.vision.skeletonDetection';
L16: import imageSuperResolution from '@hms.ai.vision.imageSuperResolution';
L17: import textSearchImage from '@hms.ai.vision.textSearchImage';
L18: export { visionBase, textRecognition, faceDetector, faceComparator, subjectSegmentation, objectDetection, skeletonDetection, imageSuperResolution, textSearchImage };
```

### `hms/ets/kits/@kit.ShareKit.d.ts`

用途：Share Kit 桶导出

```ts
L9: import systemShare from '@hms.collaboration.systemShare';
L10: import harmonyShare from '@hms.collaboration.harmonyShare';
L11: export { systemShare, harmonyShare };
```

### `hms/ets/kits/@kit.CloudFoundationKit.d.ts`

用途：Cloud Foundation Kit 桶导出

```ts
L9: import cloudCommon from '@hms.core.deviceCloudGateway.cloudCommon';
L10: import cloudFunction from '@hms.core.deviceCloudGateway.cloudFunction';
L11: import cloudStorage from '@hms.core.deviceCloudGateway.cloudStorage';
L12: import cloudDatabase from '@hms.core.deviceCloudGateway.cloudDatabase';
L13: import cloudResPrefetch from '@hms.core.deviceCloudGateway.cloudResPrefetch';
L14: export { cloudCommon, cloudFunction, cloudStorage, cloudDatabase, cloudResPrefetch };
```

### `hms/ets/kits/@kit.AgentFrameworkKit.d.ts`

用途：Agent Framework Kit 桶导出

```ts
L9: import { Role, TaskState, Part, Message, Artifact, TaskStatus, Task, OnDataCallback, createA2AServer, ProxySender, Server, AgentOperation, RequestContext, TaskArtifactParam } from '@hms.ai.A2A';
L10: import { AgentController, BaseOptions, FunctionController, FunctionOptions, ButtonType, FunctionComponent } from '@hms.ai.AgentFramework';
L11: export { AgentController, BaseOptions, FunctionController, FunctionOptions, ButtonType, FunctionComponent, Role, TaskState, Part, Message, Artifact, TaskStatus, Task, OnDataCallback, createA2AServer, ProxySender, Server, AgentOperation, RequestContext, TaskArtifactParam };
```

### `hms/ets/kits/@kit.IntentsKit.d.ts`

用途：Intents Kit 桶导出

```ts
L9: import insightIntent from '@hms.ai.insightIntent';
L10: import InsightIntentUIExtensionAbility from '@hms.ai.insightIntent.InsightIntentUIExtensionAbility';
L11: export { insightIntent, InsightIntentUIExtensionAbility };
```

### `openharmony/ets/kits/@kit.AccessibilityKit.d.ts`

用途：Accessibility Kit 桶导出（OpenHarmony 侧，hms 侧没有这个文件）

```ts
L21: import accessibility from '@ohos.accessibility';
L22: import { GesturePath } from '@ohos.accessibility.GesturePath';
L23: import { GesturePoint } from '@ohos.accessibility.GesturePoint';
L24: import AccessibilityExtensionAbility, { AccessibilityElement, AccessibilityExtensionContext, ElementAttributeKeys, ElementAttributeValues, FocusDirection, FocusType, Rect, WindowType, AccessibilityEvent } from '@ohos.application.AccessibilityExtensionAbility';
L25: export { AccessibilityElement, AccessibilityExtensionAbility, AccessibilityExtensionContext, ElementAttributeKeys, ElementAttributeValues, FocusDirection, FocusType, GesturePath, GesturePoint, Rect, WindowType, accessibility, AccessibilityEvent };
```

### `openharmony/ets/kits/@kit.AbilityKit.d.ts`

用途：Ability Kit 桶导出

```ts
L19: import ability from '@ohos.ability.ability';
L20: import { ErrorCode } from '@ohos.ability.errorCode';
L21: import featureAbility from '@ohos.ability.featureAbility';
L22: import particleAbility from '@ohos.ability.particleAbility';
L23: import abilityAccessCtrl, { Context, PermissionRequestResult, Permissions } from '@ohos.abilityAccessCtrl';
L24: import Ability from '@ohos.app.ability.Ability';
L25: import AbilityConstant from '@ohos.app.ability.AbilityConstant';
L26: import AbilityLifecycleCallback from '@ohos.app.ability.AbilityLifecycleCallback';
L27: import abilityManager from '@ohos.app.ability.abilityManager';
L28: import AbilityStage from '@ohos.app.ability.AbilityStage';
L29: import ActionExtensionAbility from '@ohos.app.ability.ActionExtensionAbility';
L30: import ApplicationStateChangeCallback from '@ohos.app.ability.ApplicationStateChangeCallback';
L31: import appManager from '@ohos.app.ability.appManager';
L32: import appRecovery from '@ohos.app.ability.appRecovery';
L33: import autoFillManager from '@ohos.app.ability.autoFillManager';
L34: import autoStartupManager from '@ohos.app.ability.autoStartupManager';
L35: import ChildProcess from '@ohos.app.ability.ChildProcess';
L36: import childProcessManager from '@ohos.app.ability.childProcessManager';
L37: import { ChildProcessArgs } from '@ohos.app.ability.ChildProcessArgs';
L38: import { ChildProcessOptions } from '@ohos.app.ability.ChildProcessOptions';
L39: import common from '@ohos.app.ability.common';
L40: import { Configuration } from '@ohos.app.ability.Configuration';
L41: import ConfigurationConstant from '@ohos.app.ability.ConfigurationConstant';
L42: import contextConstant from '@ohos.app.ability.contextConstant';
L43: import dataUriUtils from '@ohos.app.ability.dataUriUtils';
L44: import dialogRequest from '@ohos.app.ability.dialogRequest';
L45: import EnvironmentCallback from '@ohos.app.ability.EnvironmentCallback';
L46: import errorManager from '@ohos.app.ability.errorManager';
L47: import ExtensionAbility from '@ohos.app.ability.ExtensionAbility';
L48: import insightIntent from '@ohos.app.ability.insightIntent';
L49: import InsightIntentContext from '@ohos.app.ability.InsightIntentContext';
L50: import insightIntentProvider from '@ohos.app.ability.insightIntentProvider';
L51: import InsightIntentExecutor from '@ohos.app.ability.InsightIntentExecutor';
L52: import { InsightIntentLink, InsightIntentPage, InsightIntentFunctionMethod, InsightIntentFunction, InsightIntentEntry, LinkParamCategory, InsightIntentForm, InsightIntentEntity } from '@ohos.app.ability.InsightIntentDecorator';
L53: import InsightIntentEntryExecutor from '@ohos.app.ability.InsightIntentEntryExecutor';
L54: import OpenLinkOptions from '@ohos.app.ability.OpenLinkOptions';
L55: import ShareExtensionAbility from '@ohos.app.ability.ShareExtensionAbility';
L56: import StartOptions from '@ohos.app.ability.StartOptions';
L57: import UIAbility, { Callee, CalleeCallback, Caller, OnReleaseCallback, OnRemoteStateChangeCallback } from '@ohos.app.ability.UIAbility';
L58: import UIExtensionAbility from '@ohos.app.ability.UIExtensionAbility';
L59: import UIExtensionContentSession from '@ohos.app.ability.UIExtensionContentSession';
L60: import Want from '@ohos.app.ability.Want';
L61: import wantConstant from '@ohos.app.ability.wantConstant';
L62: import wantAgent, { WantAgent } from '@ohos.app.ability.wantAgent';
L63: import uriPermissionManager from '@ohos.application.uriPermissionManager';
L64: import bundleManager from '@ohos.bundle.bundleManager';
L65: import bundle from '@ohos.bundle';
L66: import defaultAppManager from '@ohos.bundle.defaultAppManager';
L67: import launcherBundleManager from '@ohos.bundle.launcherBundleManager';
L68: import overlay from '@ohos.bundle.overlay';
L69: import continuationManager from '@ohos.continuation.continuationManager';
L70: import continueManager from '@ohos.app.ability.continueManager';
L71: import Package, { CheckPackageHasInstalledOptions, CheckPackageHasInstalledResponse } from '@system.package';
L72: import privacyManager from '@ohos.privacyManager';
L73: import EmbeddedUIExtensionAbility from '@ohos.app.ability.EmbeddedUIExtensionAbility';
L74: import StartupConfig from '@ohos.app.appstartup.StartupConfig';
L75: import StartupConfigEntry from '@ohos.app.appstartup.StartupConfigEntry';
L76: import StartupListener from '@ohos.app.appstartup.StartupListener';
L77: import StartupTask from '@ohos.app.appstartup.StartupTask';
L78: import startupManager from '@ohos.app.appstartup.startupManager';
L79: import sendableContextManager from '@ohos.app.ability.sendableContextManager';
L80: import screenLockFileManager from '@ohos.ability.screenLockFileManager';
L81: import AtomicServiceOptions from '@ohos.app.ability.AtomicServiceOptions';
L82: import EmbeddableUIAbility from '@ohos.app.ability.EmbeddableUIAbility';
L83: import PhotoEditorExtensionAbility from '@ohos.app.ability.PhotoEditorExtensionAbility';
L84: import shortcutManager from '@ohos.bundle.shortcutManager';
L85: import skillManager from '@ohos.bundle.skillManager';
L86: import scriptManager from '@ohos.app.ability.scriptManager';
L87: import application from '@ohos.app.ability.application';
L88: import CompletionHandler from '@ohos.app.ability.CompletionHandler';
L89: import AppServiceExtensionAbility from '@ohos.app.ability.AppServiceExtensionAbility';
L90: import kioskManager from '@ohos.app.ability.kioskManager';
L91: import CompletionHandlerForAtomicService, { FailureCode } from '@ohos.app.ability.CompletionHandlerForAtomicService';
L92: import { CompletionHandlerForAbilityStartCallback, AbilityStartFailureCode } from '@ohos.app.ability.CompletionHandlerForAbilityStartCallback';
L93: import systemConfiguration from '@ohos.app.ability.systemConfiguration';
L94: import AgentExtensionAbility from '@ohos.app.agent.AgentExtensionAbility';
L95: import AgentUIExtensionAbility from '@ohos.app.agent.AgentUIExtensionAbility';
L96: import agentConstant from '@ohos.app.agent.agentConstant';
L97: import hyperSnapManager from '@ohos.app.ability.hyperSnapManager';
L98: import pluginBundleManager from '@ohos.bundle.pluginBundleManager';
L99: export { Ability, AbilityConstant, AbilityLifecycleCallback, AbilityStage, ActionExtensionAbility, ApplicationStateChangeCallback, Callee, CalleeCallback, Caller, CheckPackageHasInstalledOptions, CheckPackageHasInstalledResponse, ChildProcess, Configuration, ConfigurationConstant, Context, EnvironmentCallback, ErrorCode, ExtensionAbility, InsightIntentContext, InsightIntentExecutor, OnReleaseCallback, OnRemoteStateChangeCallback, OpenLinkOptions, Package, PermissionRequestResult, Permissions, ShareExtensionAbility, StartOptions, UIAbility, UIExtensionAbility, UIExtensionContentSession, Want, WantAgent, ability, abilityAccessCtrl, abilityManager, appManager, appRecovery, autoFillManager, autoStartupManager, bundle, bundleManager, childProcessManager, common, contextConstant, continuationManager, continueManager, dataUriUtils, defaultAppManager, dialogRequest, errorManager, featureAbility, insightIntent, insightIntentProvider, launcherBundleManager, overlay, particleAbility, uriPermissionManager, wantAgent, wantConstant, privacyManager, EmbeddedUIExtensionAbility, StartupConfig, StartupConfigEntry, StartupListener, StartupTask, startupManager, screenLockFileManager, AtomicServiceOptions, EmbeddableUIAbility, ChildProcessArgs, ChildProcessOptions, sendableContextManager, PhotoEditorExtensionAbility, shortcutManager, skillManager, scriptManager, application, InsightIntentLink, InsightIntentPage, InsightIntentFunctionMethod, InsightIntentFunction, InsightIntentEntryExecutor, InsightIntentEntry, LinkParamCategory, CompletionHandler, AppServiceExtensionAbility, InsightIntentForm, InsightIntentEntity, kioskManager, CompletionHandlerForAtomicService, CompletionHandlerForAbilityStartCallback, AbilityStartFailureCode, FailureCode, systemConfiguration, AgentExtensionAbility, AgentUIExtensionAbility, agentConstant, hyperSnapManager, pluginBundleManager };
```

### `openharmony/ets/kits/@kit.ArkData.d.ts`

用途：ArkData 桶导出

```ts
L21: import cloudData from '@ohos.data.cloudData';
L22: import cloudExtension from '@ohos.data.cloudExtension';
L23: import commonType from '@ohos.data.commonType';
L24: import dataAbility from '@ohos.data.dataAbility';
L25: import dataShare from '@ohos.data.dataShare';
L26: import dataSharePredicates from '@ohos.data.dataSharePredicates';
L27: import distributedDataObject from '@ohos.data.distributedDataObject';
L28: import distributedKVStore from '@ohos.data.distributedKVStore';
L29: import preferences from '@ohos.data.preferences';
L30: import relationalStore from '@ohos.data.relationalStore';
L31: import unifiedDataChannel from '@ohos.data.unifiedDataChannel';
L32: import uniformTypeDescriptor from '@ohos.data.uniformTypeDescriptor';
L33: import uniformDataStruct from '@ohos.data.uniformDataStruct';
L34: import { ValueType, ValuesBucket } from '@ohos.data.ValuesBucket';
L35: import sendablePreferences from '@ohos.data.sendablePreferences';
L36: import sendableRelationalStore from '@ohos.data.sendableRelationalStore';
L37: import intelligence from '@ohos.data.intelligence';
L38: import { ContentFormCard, FormType } from '@ohos.data.UdmfComponents';
L39: export { ValueType, ValuesBucket, cloudData, cloudExtension, commonType, dataShare, dataSharePredicates, distributedDataObject, distributedKVStore, preferences, relationalStore, unifiedDataChannel, uniformTypeDescriptor, uniformDataStruct, sendablePreferences, dataAbility, sendableRelationalStore, intelligence, ContentFormCard, FormType };
```

### `openharmony/ets/kits/@kit.ArkUI.d.ts`

用途：ArkUI 桶导出（uiMaterial 等）

```ts
L21: import Animator, { AnimatorOptions, AnimatorResult, SimpleAnimatorOptions } from '@ohos.animator';
L22: import { AtomicServiceNavigation, NavDestinationBuilder, MixMode, GradientAlpha, BackgroundTheme, TitleBarType, SideBarOptions, TitleOptions, GradientBackground } from '@ohos.atomicservice.AtomicServiceNavigation';
L23: import { AtomicServiceSearch, InputFilterParams, SearchButtonParams, MenuAlignParams, SearchParams, SelectParams, OperationParams, } from '@ohos.atomicservice.AtomicServiceSearch';
L24: import { ArcButton, ArcButtonOptions, ArcButtonProgressConfig, ArcButtonPosition, ArcButtonStyleMode, ArcButtonStatus } from '@ohos.arkui.advanced.ArcButton';
L25: import { Chip, ChipOptions, ChipSize, IconCommonOptions, LabelMarginOptions, LabelOptions, PrefixIconOptions, SuffixIconOptions, ChipSymbolGlyphOptions, AccessibilitySelectedType, AccessibilityOptions, CloseOptions, ChipSuffixSymbolGlyphOptions } from '@ohos.arkui.advanced.Chip';
L26: import { ChipV2Size, ChipV2AccessibilitySelectedType, ChipV2ImageIconConfig, ChipV2ImageIcon, ChipV2SuffixImageIconConfig, ChipV2SuffixImageIcon, ChipV2Icon, ChipV2PrefixImageIconConfig, ChipV2PrefixImageIcon, ChipV2AccessibilityConfig, ChipV2Accessibility, ChipV2CloseConfig, ChipV2CloseIcon, ChipV2SymbolIconConfig, ChipV2SymbolIcon, ChipV2PrefixSymbolIconConfig, ChipV2PrefixSymbolIcon, ChipV2SuffixSymbolIconConfig, ChipV2SuffixSymbolIcon, ChipV2LabelMarginConfig, ChipV2LocalizedLabelMarginConfig, ChipV2LabelConfig, ChipV2Label, IChipV2OptionsConfig, ChipV2Options, ChipV2 } from '@ohos.arkui.advanced.ChipV2';
L27: import { NavPushPathHelper } from '@ohos.atomicservice.NavPushPathHelper';
L28: import { IconOptions, LabelOptions as ChipItemLabelOptions, ChipGroupItemOptions, ChipItemStyle, ChipGroupSpaceOptions, IconItemOptions, IconGroupSuffix, ChipGroup, SuffixImageIconOptions, SymbolItemOptions } from '@ohos.arkui.advanced.ChipGroup';
L29: import { ChipGroupV2ItemConfig, ChipGroupV2Item, ChipGroupV2Items, ChipGroupV2ItemStyleConfig, ChipGroupV2ItemStyle, ChipGroupV2SpaceConfig, ChipGroupV2Space, ChipGroupV2IconItemConfig, ChipGroupV2SymbolItemConfig, ChipGroupV2PaddingConfig, ChipGroupV2Padding, ChipGroupV2IconGroupSuffix, ChipGroupV2 } from '@ohos.arkui.advanced.ChipGroupV2';
L30: import { ComposeListItem, ContentItem, IconType, OperateButton, OperateCheck, OperateIcon, OperateItem } from '@ohos.arkui.advanced.ComposeListItem';
L31: import { ComposeListItemV2, ContentItemV2, ContentItemV2Options, IconTypeV2, OperateButtonV2, OperateButtonV2Options, OperateCheckV2, OperateCheckV2Options, OperateIconV2, OperateIconV2Options, OperateItemV2, OperateItemV2Options } from '@ohos.arkui.advanced.ComposeListItemV2';
L32: import { ComposeTitleBar, ComposeTitleBarMenuItem } from '@ohos.arkui.advanced.ComposeTitleBar';
L33: import { ComposeTitleBarV2, ComposeTitleBarV2MenuItem, ComposeTitleBarV2MenuItemParams } from '@ohos.arkui.advanced.ComposeTitleBarV2';
L34: import { CounterComponent, CounterOptions, CounterType, DateData } from '@ohos.arkui.advanced.Counter';
L35: import { CounterV2Component, CounterV2Options, CounterV2DateData, CounterV2Type } from '@ohos.arkui.advanced.CounterV2';
L36: import { DatePickerComponent, DatePickerComponentOptions, DisplayMode, DateMode, TimeFormat, DatePickerComponentResult } from '@ohos.arkui.advanced.DatePickerComponent';
L37: import { AlertDialog, ButtonOptions, ConfirmDialog, LoadingDialog, SelectDialog, TipsDialog, CustomContentDialog, PopoverDialog, PopoverOptions } from '@ohos.arkui.advanced.Dialog';
L38: import { AlertDialogV2, AdvancedDialogV2Button, AdvancedDialogV2ButtonOptions, AdvancedDialogV2ButtonAction, AdvancedDialogV2OnCheckedChange, ConfirmDialogV2, LoadingDialogV2, SelectDialogV2, TipsDialogV2, CustomContentDialogV2, PopoverDialogV2, PopoverDialogV2OnVisibleChange, PopoverDialogV2Options } from '@ohos.arkui.advanced.DialogV2';
L39: import { EditableLeftIconType, EditableTitleBar, EditableTitleBarMenuItem, EditableTitleBarItem, EditableTitleBarOptions } from '@ohos.arkui.advanced.EditableTitleBar';
L40: import { EditableLeftIconTypeV2, EditableTitleBarV2, EditableLeftIconV2, EditableLeftIconV2Options, EditableTitleV2, EditableTitleV2Options, EditableTitleBarItemV2, EditableTitleBarItemV2Options, EditableTitleBarMenuItemV2, EditableTitleBarMenuItemV2Options, EditableSaveButtonV2, EditableSaveButtonV2Options, EditableTitleBarStyleV2, EditableTitleBarStyleV2Options } from '@ohos.arkui.advanced.EditableTitleBarV2';
L41: import { MarginType, PromptOptions, ExceptionPrompt } from '@ohos.arkui.advanced.ExceptionPrompt';
L42: import { MarginTypeV2, PromptOptionsV2, PromptOptionsV2Config, ExceptionPromptV2 } from '@ohos.arkui.advanced.ExceptionPromptV2';
L43: import { Filter, FilterParams, FilterResult, FilterType } from '@ohos.arkui.advanced.Filter';
L44: import { AddFormMenuItem, FormMenuItemStyle, AddFormOptions } from '@ohos.arkui.advanced.FormMenu';
L45: import { GridObjectSortComponentType, GridObjectSortComponentItem, GridObjectSortComponentOptions, GridObjectSortComponent } from '@ohos.arkui.advanced.GridObjectSortComponent';
L46: import { Popup, PopupButtonOptions, PopupIconOptions, PopupOptions, PopupTextOptions } from '@ohos.arkui.advanced.Popup';
L47: import { PopupV2, PopupV2InitInfo, PopupV2Button } from '@ohos.arkui.advanced.PopupV2';
L48: import { ProgressButton } from '@ohos.arkui.advanced.ProgressButton';
L49: import { ProgressButtonV2, ProgressButtonV2Color, ProgressButtonV2ColorOptions } from '@ohos.arkui.advanced.ProgressButtonV2';
L50: import { SegmentButton, SegmentButtonOptions, SegmentButtonItemOptionsArray, TabSegmentButtonOptions, TabSegmentButtonConstructionOptions, CapsuleSegmentButtonOptions, CapsuleSegmentButtonConstructionOptions, SegmentButtonTextItem, SegmentButtonIconItem, SegmentButtonIconTextItem, DimensionNoPercentage, CommonSegmentButtonOptions, ItemRestriction, SegmentButtonItemTuple, SegmentButtonItemArray, SegmentButtonItemOptionsConstructorOptions, SegmentButtonItemOptions, BorderRadiusMode } from '@ohos.arkui.advanced.SegmentButton';
L51: import { EditorEventInfo, EditorMenuOptions, ExpandedMenuOptions, SelectionMenu, SelectionMenuOptions } from '@ohos.arkui.advanced.SelectionMenu';
L52: import { SelectTitleBar, SelectTitleBarMenuItem } from '@ohos.arkui.advanced.SelectTitleBar';
L53: import { SplitLayout } from '@ohos.arkui.advanced.SplitLayout';
L54: import { OperationOption, OperationType, SelectOptions, SubHeader, SymbolOptions } from '@ohos.arkui.advanced.SubHeader';
L55: import { SwipeRefresher } from '@ohos.arkui.advanced.SwipeRefresher';
L56: import { SwipeRefresherV2 } from '@ohos.arkui.advanced.SwipeRefresherV2';
L57: import { TabTitleBar, TabTitleBarMenuItem, TabTitleBarTabItem } from '@ohos.arkui.advanced.TabTitleBar';
L58: import { ItemState, ToolBar, ToolBarOption, ToolBarOptions, ToolBarModifier } from '@ohos.arkui.advanced.ToolBar';
L59: import { ToolBarV2ItemState, ToolBarV2SymbolGlyph, ToolBarV2SymbolGlyphOptions, ToolBarV2ItemText, ToolBarV2ItemTextOptions, ToolBarV2ItemIconType, ToolBarV2ItemImage, ToolBarV2ItemImageOptions, ToolBarV2, ToolBarV2Item, ToolBarV2ItemOptions, ToolBarV2Modifier, ToolBarV2ItemAction } from '@ohos.arkui.advanced.ToolBarV2';
L60: import { CallbackParam, NodeParam, TreeController, TreeListenType, TreeListener, TreeListenerManager, TreeView } from '@ohos.arkui.advanced.TreeView';
L61: import { CallbackParamV2, NodeParamV2, TreeControllerV2, TreeListenerV2, TreeListenerManagerV2, TreeViewV2 } from '@ohos.arkui.advanced.TreeViewV2';
L62: import { InterstitialDialogAction, IconStyle, TitlePosition, BottomOffset } from '@ohos.atomicservice.InterstitialDialogAction';
L63: import componentSnapshot from '@ohos.arkui.componentSnapshot';
L64: import componentUtils from '@ohos.arkui.componentUtils';
L65: import dragController from '@ohos.arkui.dragController';
L66: import { DrawableDescriptor, LayeredDrawableDescriptor, PixelMapDrawableDescriptor, AnimationOptions, AnimatedDrawableDescriptor, AnimationController, DrawableDescriptorLoadedResult, AnimationStopMode, PictureDrawableDescriptor, HdrCompositionConfig } from '@ohos.arkui.drawableDescriptor';
L67: import inspector from '@ohos.arkui.inspector';
L68: import { NodeRenderType, RenderOptions, BuilderNode, ReactiveBuilderNode, BuildOptions, NodeController, FrameNode, DrawContext, Size, Offset, Position, Pivot, Scale, Translation, Matrix4, Rotation, Frame, RenderNode, XComponentNode, LengthMetrics, ColorMetrics, BackgroundBlur, ContentBlur, ForegroundBlur, LengthUnit, LengthMetricsUnit, LayoutConstraint, ComponentContent, ReactiveComponentContent, NodeContent, Content, typeNode, NodeAdapter, ShapeMask, ShapeClip, Rect, RoundRect, edgeColors, edgeWidths, borderStyles, borderRadiuses, ExpandMode, ChildrenCountMode, UIState, InputEventType } from '@ohos.arkui.node';
L69: import uiObserver from '@ohos.arkui.observer';
L70: import { AppStorageV2, PersistenceV2, Type, UIUtils, ConnectOptions, Binding, MutableBinding, CustomComponentLifecycle, CustomComponentLifecycleObserver, CustomComponentLifecycleState, ComponentInit, ComponentAppear, ComponentBuilt, ComponentReuse, ComponentActive, ComponentInactive, ComponentRecycle, ComponentDisappear, CollectionType, ConnectOptionsCollections, CustomComponentContext, IReusePool, IReusableInfo } from '@ohos.arkui.StateManagement';
L71: import { RectShape, CircleShape, EllipseShape, PathShape } from '@ohos.arkui.shape';
L72: import { AtomicServiceBar, ComponentUtils, ContextMenuController, CursorController, DragController, Font, KeyboardAvoidMode, MediaQuery, OverlayManager, PromptAction, Router, UIContext, UIInspector, UIObserver, PageInfo, SwiperDynamicSyncScene, SwiperDynamicSyncSceneType, MarqueeDynamicSyncScene, MarqueeDynamicSyncSceneType, MeasureUtils, FrameCallback, OverlayManagerOptions, TargetInfo, TextMenuController, NodeIdentity, NodeRenderState, NodeRenderStateChangeCallback, Magnifier, ResolvedUIContext, TextSelectionClearPolicy } from '@ohos.arkui.UIContext';
L73: import curves from '@ohos.curves';
L74: import { AtomicServiceWeb, OnMessageEvent, OnErrorReceiveEvent, OnHttpErrorReceiveEvent, OnPageBeginEvent, OnPageEndEvent, AtomicServiceWebController, OnLoadInterceptEvent, OnProgressChangeEvent, OnLoadInterceptCallback, WebHeader } from '@ohos.atomicservice.AtomicServiceWeb';
L75: import display from '@ohos.display';
L76: import font from '@ohos.font';
L77: import matrix4 from '@ohos.matrix4';
L78: import MeasureText, { MeasureOptions } from '@ohos.measure';
L79: import mediaquery from '@ohos.mediaquery';
L80: import PiPWindow from '@ohos.PiPWindow';
L81: import floatingBall from '@ohos.window.floatingBall';
L82: import floatView from '@ohos.window.floatView';
L83: import pluginComponentManager, { PluginComponentTemplate } from '@ohos.pluginComponent';
L84: import prompt from '@ohos.prompt';
L85: import promptAction, { LevelMode, ImmersiveMode, LevelOrder } from '@ohos.promptAction';
L86: import router from '@ohos.router';
L87: import screenshot from '@ohos.screenshot';
L88: import uiAppearance from '@ohos.uiAppearance';
L89: import window from '@ohos.window';
L90: import App, { AppResponse, RequestFullWindowOptions, ScreenOnVisibleOptions } from '@system.app';
L91: import Configuration, { LocaleResponse } from '@system.configuration';
L92: import SystemMediaQuery, { MediaQueryEvent, MediaQueryList } from '@system.mediaquery';
L93: import Prompt, { Button, ShowActionMenuOptions, ShowDialogOptions, ShowDialogSuccessResponse, ShowToastOptions } from '@system.prompt';
L94: import SystemRouter, { BackRouterOptions, DisableAlertBeforeBackPageOptions, EnableAlertBeforeBackPageOptions, RouterOptions, RouterState } from '@system.router';
L95: import { ArcList, ArcListItem, ArcListAttribute, ArcListItemAttribute } from '@ohos.arkui.ArcList';
L96: import { ArcAlphabetIndexer, ArcAlphabetIndexerAttribute } from '@ohos.arkui.ArcAlphabetIndexer';
L97: import { ArcScrollBar, ArcScrollBarAttribute } from '@ohos.arkui.ArcScrollBar';
L98: import { Colors, CustomColors, Theme, ThemeControl, CustomTheme, CustomDarkColors } from '@ohos.arkui.theme';
L99: import { ExtraRegionPosition, ExpandedRegionLayoutOptions, HoverModeRegionLayoutOptions, FoldedRegionLayoutOptions, PresetSplitRatio, FoldSplitContainer, HoverModeStatus, OnHoverStatusChangeHandler, } from '@ohos.arkui.advanced.FoldSplitContainer';
L100: import uiExtension from '@ohos.arkui.uiExtension';
L101: import { FullScreenLaunchComponent } from '@ohos.arkui.advanced.FullScreenLaunchComponent';
L102: import { AtomicServiceTabs, TabBarOptions, TabBarPosition, TabContentBuilder, OnContentWillChangeCallback } from '@ohos.atomicservice.AtomicServiceTabs';
L103: import { CommonModifier, ColumnModifier, ColumnSplitModifier, RowModifier, RowSplitModifier, SideBarContainerModifier, BlankModifier, DividerModifier, GridColModifier, GridRowModifier, NavDestinationModifier, NavigatorModifier, StackModifier, NavigationModifier, NavRouterModifier, StepperItemModifier, TabsModifier, GridModifier, GridItemModifier, ListModifier, ListItemModifier, ListItemGroupModifier, ScrollModifier, SwiperModifier, WaterFlowModifier, ButtonModifier, CounterModifier, TextPickerModifier, TimePickerModifier, ToggleModifier, CalendarPickerModifier, CheckboxModifier, CheckboxGroupModifier, DatePickerModifier, RadioModifier, RatingModifier, SelectModifier, SliderModifier, PatternLockModifier, SpanModifier, RichEditorModifier, RefreshModifier, SearchModifier, TextAreaModifier, TextModifier, TextInputModifier, ImageSpanModifier, ImageAnimatorModifier, ImageModifier, VideoModifier, DataPanelModifier, GaugeModifier, LoadingProgressModifier, MarqueeModifier, ProgressModifier, QRCodeModifier, TextClockModifier, TextTimerModifier, LineModifier, PathModifier, PolygonModifier, PolylineModifier, RectModifier, ShapeModifier, AlphabetIndexerModifier, HyperlinkModifier, MenuModifier, MenuItemModifier, PanelModifier, SymbolGlyphModifier, AttributeUpdater, ContainerSpanModifier, SymbolSpanModifier, ParticleModifier, StepperModifier, UIPickerComponentModifier, ModifierUtils } from '@ohos.arkui.modifier';
L104: import { IDataSourcePrefetching, IPrefetcher, BasicPrefetcher } from '@ohos.arkui.Prefetcher';
L105: import { DownloadFileButton, DownloadLayoutDirection, DownloadIconStyle, DownloadDescription, DownloadContentOptions, DownloadStyleOptions } from '@ohos.arkui.advanced.DownloadFileButton';
L106: import { SplitPolicy, MultiNavigation, MultiNavPathStack } from '@ohos.arkui.advanced.MultiNavigation';
L107: import { ArcSlider, ArcSliderPosition, ArcSliderOptions, ArcSliderOptionsConstructorOptions, ArcSliderLayoutOptions, ArcSliderLayoutOptionsConstructorOptions, ArcSliderStyleOptions, ArcSliderStyleOptionsConstructorOptions, ArcSliderValueOptions, ArcSliderValueOptionsConstructorOptions } from '@ohos.arkui.advanced.ArcSlider';
L108: import { ArcSwiper, ArcSwiperAttribute, ArcDotIndicator, ArcDirection, ArcSwiperController } from '@ohos.arkui.ArcSwiper';
L109: import { SubHeaderV2IconType, SubHeaderV2Title, SubHeaderV2Select, SubHeaderV2, SubHeaderV2OperationType, SubHeaderV2OperationItem, SubHeaderV2OperationItemType } from '@ohos.arkui.advanced.SubHeaderV2';
L110: import { SegmentButtonV2ItemOptions, OnSelectedIndexChange, OnSelectedIndexesChange, SegmentButtonV2Item, SegmentButtonV2Items, TabSegmentButtonV2, CapsuleSegmentButtonV2, MultiCapsuleSegmentButtonV2 } from '@ohos.arkui.advanced.SegmentButtonV2';
L111: import { HalfScreenLaunchComponent } from '@ohos.atomicservice.HalfScreenLaunchComponent';
L112: import { GestureListenerType, GestureActionPhase, GestureTriggerInfo, GestureObserverConfigs, GestureListenerCallback } from '@ohos.arkui.UIContext';
L113: import { SwiperContentInfo, SwiperItemInfo } from '@ohos.arkui.UIContext';
L114: import { BackPressActionProposal, BaseGestureHandlingProposal, ClickActionProposal, GestureHandlingResolution, NoneActionProposal, PageSwitchActionProposal, ScrollActionProposal, SelectActionProposal, SmartGestureController, TargetedGestureProposal } from '@ohos.arkui.UIContext';
L115: import uiMaterial from '@ohos.arkui.uiMaterial';
L116: import { RowLayoutAlgorithm, ColumnLayoutAlgorithm, StackLayoutAlgorithm, GridLayoutAlgorithm, CustomLayoutAlgorithm, LayoutAlgorithm } from '@ohos.arkui.layoutAlgorithm';
L117: import { LazyLayoutDirection, LazyLayoutHelper, LazyCustomLayoutAlgorithmOptions, LazyCustomLayoutAlgorithm, LazyLayoutAlgorithm } from '@ohos.arkui.lazyLayoutAlgorithm';
L118: import { DynamicLayout, DynamicLayoutAttribute } from '@ohos.arkui.components.ArkDynamicLayout';
L119: import { ContainerReader, ContainerReaderAttribute, BreakpointOptions } from '@ohos.arkui.components.ContainerReader';
L120: import { WithEnv, WithEnvAttribute } from '@ohos.arkui.WithEnv';
L121: import { LazyVWaterFlowLayout, LazyVWaterFlowLayoutAttribute, LazyWaterFlowLayoutAttribute } from '@ohos.arkui.components.ArkLazyWaterFlowLayout';
L122: import { LazyColumnLayout, LazyColumnLayoutAttribute } from '@ohos.arkui.components.ArkLazyColumnLayout';
L123: import { LazyDynamicLayout, LazyDynamicLayoutAttribute } from '@ohos.arkui.components.ArkLazyDynamicLayout';
L124: import { OnMenuItemClickWithTextCallback, SelectionContainer, SelectionContainerAttribute, SelectionContainerEditMenuOptions, SelectionContainerInstance, SelectionContainerMenuOptions, SelectionContainerTextJoinStyle } from '@ohos.arkui.components.SelectionContainer';
L125: export { AtomicServiceSearch, InputFilterParams, SearchButtonParams, MenuAlignParams, SearchParams, SelectParams, OperationParams, AddFormMenuItem, AddFormOptions, AlertDialog, Animator, AnimatorOptions, AnimatorResult, SimpleAnimatorOptions, App, AppResponse, AtomicServiceBar, AtomicServiceNavigation, NavDestinationBuilder, MixMode, GradientAlpha, BackgroundTheme, TitleBarType, SideBarOptions, TitleOptions, GradientBackground, NavPushPathHelper, BackRouterOptions, BuilderNode, ReactiveBuilderNode, Button, ButtonOptions, CallbackParam, ArcButton, ArcButtonOptions, ArcButtonProgressConfig, ArcButtonPosition, ArcButtonStyleMode, ArcButtonStatus, ChipV2Size, ChipV2AccessibilitySelectedType, ChipV2ImageIconConfig, ChipV2ImageIcon, ChipV2SuffixImageIconConfig, ChipV2SuffixImageIcon, ChipV2Icon, ChipV2PrefixImageIconConfig, ChipV2PrefixImageIcon, ChipV2AccessibilityConfig, ChipV2Accessibility, ChipV2CloseConfig, ChipV2CloseIcon, ChipV2SymbolIconConfig, ChipV2SymbolIcon, ChipV2PrefixSymbolIconConfig, ChipV2PrefixSymbolIcon, ChipV2SuffixSymbolIconConfig, ChipV2SuffixSymbolIcon, ChipV2LabelMarginConfig, ChipV2LocalizedLabelMarginConfig, ChipV2LabelConfig, ChipV2Label, IChipV2OptionsConfig, ChipV2Options, ChipV2, ChipGroupV2ItemConfig, ChipGroupV2Item, ChipGroupV2Items, ChipGroupV2ItemStyleConfig, ChipGroupV2ItemStyle, ChipGroupV2SpaceConfig, ChipGroupV2Space, ChipGroupV2IconItemConfig, ChipGroupV2SymbolItemConfig, ChipGroupV2PaddingConfig, ChipGroupV2Padding, ChipGroupV2IconGroupSuffix, ChipGroupV2, CapsuleSegmentButtonConstructionOptions, CapsuleSegmentButtonOptions, Chip, ChipOptions, ChipSize, CircleShape, ComponentUtils, ComposeListItem, ComposeTitleBar, ComposeTitleBarMenuItem, Configuration, ConfirmDialog, ContentItem, ContextMenuController, CounterComponent, CounterOptions, CounterType, CursorController, DateData, CounterV2Component, CounterV2Options, CounterV2DateData, CounterV2Type, DisableAlertBeforeBackPageOptions, DragController, DrawableDescriptor, DrawContext, EditableLeftIconType, EditableTitleBar, EditableTitleBarItem, EditableTitleBarOptions, EditableTitleBarMenuItem, EditorEventInfo, EditorMenuOptions, EllipseShape, EnableAlertBeforeBackPageOptions, ExceptionPrompt, ExpandedMenuOptions, Filter, FilterParams, FilterResult, FilterType, Font, FormMenuItemStyle, Frame, FrameCallback, FrameNode, GridObjectSortComponent, GridObjectSortComponentItem, GridObjectSortComponentOptions, GridObjectSortComponentType, IconCommonOptions, IconType, ItemState, KeyboardAvoidMode, LabelMarginOptions, InterstitialDialogAction, IconStyle, TitlePosition, BottomOffset, LabelOptions, LayeredDrawableDescriptor, LoadingDialog, LocaleResponse, MarginType, Matrix4, MeasureOptions, MeasureText, MediaQuery, MediaQueryEvent, MediaQueryList, NodeController, NodeParam, NodeRenderType, Offset, OperateButton, OperateCheck, OperateIcon, OperateItem, OperationOption, OperationType, OverlayManager, PathShape, PiPWindow, Pivot, Popup, PopupButtonOptions, PopupIconOptions, PopupOptions, PopupTextOptions, Position, PrefixIconOptions, ProgressButton, ProgressButtonV2, ProgressButtonV2Color, ProgressButtonV2ColorOptions, Prompt, PromptAction, PromptOptions, RectShape, RenderNode, RenderOptions, BuildOptions, RequestFullWindowOptions, Rotation, Router, RouterOptions, RouterState, Scale, ScreenOnVisibleOptions, SegmentButton, SegmentButtonItemOptionsArray, SegmentButtonOptions, SelectDialog, SelectOptions, SelectTitleBar, SelectTitleBarMenuItem, SelectionMenu, SelectionMenuOptions, ShapeMask, ShapeClip, ShowActionMenuOptions, ShowDialogOptions, ShowDialogSuccessResponse, AppStorageV2, PersistenceV2, Type, UIUtils, ConnectOptions, Binding, MutableBinding, ShowToastOptions, Size, SplitLayout, SubHeader, SuffixIconOptions, SwipeRefresher, SymbolOptions, SystemMediaQuery, SystemRouter, SubHeaderV2IconType, SubHeaderV2Title, SubHeaderV2Select, SubHeaderV2, SubHeaderV2OperationType, SubHeaderV2OperationItem, SubHeaderV2OperationItemType, TabSegmentButtonConstructionOptions, TabSegmentButtonOptions, TabTitleBar, TabTitleBarMenuItem, TabTitleBarTabItem, TipsDialog, ToolBar, ToolBarOption, ToolBarOptions, ToolBarModifier, Translation, TreeController, TreeListenType, TreeListener, ToolBarV2ItemState, ToolBarV2SymbolGlyph, ToolBarV2SymbolGlyphOptions, ToolBarV2ItemText, ToolBarV2ItemTextOptions, ToolBarV2ItemIconType, ToolBarV2ItemImage, ToolBarV2ItemImageOptions, ToolBarV2, ToolBarV2Item, ToolBarV2ItemOptions, ToolBarV2Modifier, ToolBarV2ItemAction, TreeListenerManager, TreeView, UIContext, UIInspector, UIObserver, PageInfo, WithEnv, WithEnvAttribute, XComponentNode, LengthMetrics, LengthUnit, ColorMetrics, BackgroundBlur, ContentBlur, ForegroundBlur, LengthMetricsUnit, LayoutConstraint, ComponentContent, ReactiveComponentContent, NodeContent, Content, componentSnapshot, componentUtils, curves, display, dragController, floatingBall, floatView, font, inspector, matrix4, mediaquery, pluginComponentManager, PluginComponentTemplate, prompt, promptAction, router, LevelMode, ImmersiveMode, LevelOrder, AtomicServiceWeb, OnMessageEvent, OnErrorReceiveEvent, OnHttpErrorReceiveEvent, OnPageBeginEvent, OnPageEndEvent, AtomicServiceWebController, OnLoadInterceptEvent, OnProgressChangeEvent, OnLoadInterceptCallback, WebHeader, screenshot, uiAppearance, uiObserver, window, CustomContentDialog, PopoverDialog, PopoverOptions, AtomicServiceTabs, TabBarOptions, TabBarPosition, TabContentBuilder, OnContentWillChangeCallback, IconOptions, ChipItemLabelOptions, ChipGroupItemOptions, ChipItemStyle, ChipGroupSpaceOptions, IconItemOptions, IconGroupSuffix, ChipGroup, Colors, CustomColors, Theme, ThemeControl, CustomTheme, CustomDarkColors, ChipSymbolGlyphOptions, ExtraRegionPosition, ExpandedRegionLayoutOptions, HoverModeRegionLayoutOptions, FoldedRegionLayoutOptions, PresetSplitRatio, FoldSplitContainer, HoverModeStatus, OnHoverStatusChangeHandler, SwiperDynamicSyncScene, SwiperDynamicSyncSceneType, MarqueeDynamicSyncScene, MarqueeDynamicSyncSceneType, uiExtension, FullScreenLaunchComponent, MeasureUtils, typeNode, CommonModifier, ColumnModifier, ColumnSplitModifier, RowModifier, RowSplitModifier, SideBarContainerModifier, BlankModifier, DividerModifier, GridColModifier, GridRowModifier, NavDestinationModifier, NavigatorModifier, StackModifier, NavigationModifier, NavRouterModifier, StepperItemModifier, TabsModifier, GridModifier, GridItemModifier, ListModifier, ListItemModifier, ListItemGroupModifier, ScrollModifier, SwiperModifier, WaterFlowModifier, ButtonModifier, CounterModifier, TextPickerModifier, TimePickerModifier, ToggleModifier, CalendarPickerModifier, CheckboxModifier, CheckboxGroupModifier, DatePickerModifier, RadioModifier, RatingModifier, SelectModifier, SliderModifier, PatternLockModifier, SpanModifier, RichEditorModifier, RefreshModifier, SearchModifier, TextAreaModifier, TextModifier, TextInputModifier, ImageSpanModifier, ImageAnimatorModifier, ImageModifier, VideoModifier, DataPanelModifier, GaugeModifier, LoadingProgressModifier, MarqueeModifier, ProgressModifier, QRCodeModifier, TextClockModifier, TextTimerModifier, LineModifier, PathModifier, PolygonModifier, PolylineModifier, RectModifier, ShapeModifier, AlphabetIndexerModifier, HyperlinkModifier, MenuModifier, MenuItemModifier, PanelModifier, SymbolGlyphModifier, AttributeUpdater, ModifierUtils, SymbolSpanModifier, ContainerSpanModifier, PixelMapDrawableDescriptor, AnimationOptions, AnimatedDrawableDescriptor, AnimationController, AnimationStopMode, DrawableDescriptorLoadedResult, PictureDrawableDescriptor, HdrCompositionConfig, IDataSourcePrefetching, IPrefetcher, BasicPrefetcher, SegmentButtonTextItem, SegmentButtonIconItem, SegmentButtonIconTextItem, DimensionNoPercentage, CommonSegmentButtonOptions, ItemRestriction, SegmentButtonItemTuple, SegmentButtonItemArray, SegmentButtonItemOptionsConstructorOptions, SegmentButtonItemOptions, BorderRadiusMode, DownloadFileButton, DownloadLayoutDirection, DownloadIconStyle, DownloadDescription, DownloadContentOptions, DownloadStyleOptions, NodeAdapter, Rect, RoundRect, edgeColors, edgeWidths, borderStyles, borderRadiuses, ParticleModifier, AccessibilitySelectedType, AccessibilityOptions, CloseOptions, ChipSuffixSymbolGlyphOptions, SuffixImageIconOptions, SymbolItemOptions, ArcList, ArcListItem, ArcListAttribute, ArcListItemAttribute, SplitPolicy, MultiNavigation, MultiNavPathStack, ArcAlphabetIndexer, ArcAlphabetIndexerAttribute, ArcSlider, ArcSliderOptions, ArcSliderOptionsConstructorOptions, ArcSliderLayoutOptions, ArcSliderLayoutOptionsConstructorOptions, ArcSliderStyleOptions, ArcSliderStyleOptionsConstructorOptions, ArcSliderValueOptions, ArcSliderValueOptionsConstructorOptions, ArcScrollBar, ArcScrollBarAttribute, OverlayManagerOptions, SegmentButtonV2ItemOptions, OnSelectedIndexChange, OnSelectedIndexesChange, SegmentButtonV2Item, SegmentButtonV2Items, TabSegmentButtonV2, CapsuleSegmentButtonV2, MultiCapsuleSegmentButtonV2, AlertDialogV2, AdvancedDialogV2Button, AdvancedDialogV2ButtonOptions, AdvancedDialogV2ButtonAction, AdvancedDialogV2OnCheckedChange, ConfirmDialogV2, LoadingDialogV2, SelectDialogV2, TipsDialogV2, CustomContentDialogV2, PopoverDialogV2, PopoverDialogV2OnVisibleChange, PopoverDialogV2Options, ExpandMode, ChildrenCountMode, Magnifier, TextSelectionClearPolicy, HalfScreenLaunchComponent, ArcSliderPosition, ArcSwiper, ArcSwiperAttribute, ArcDotIndicator, ArcDirection, ArcSwiperController, TargetInfo, UIState, StepperModifier, TextMenuController, InputEventType, GestureListenerType, GestureActionPhase, GestureTriggerInfo, GestureObserverConfigs, GestureListenerCallback, NodeIdentity, NodeRenderState, NodeRenderStateChangeCallback, UIPickerComponentModifier, SwiperContentInfo, SwiperItemInfo, ResolvedUIContext, CustomComponentLifecycle, CustomComponentLifecycleObserver, CustomComponentLifecycleState, ComponentInit, ComponentAppear, ComponentBuilt, ComponentReuse, ComponentRecycle, ComponentDisappear, ComponentActive, ComponentInactive, CollectionType, ConnectOptionsCollections, uiMaterial, RowLayoutAlgorithm, ColumnLayoutAlgorithm, StackLayoutAlgorithm, GridLayoutAlgorithm, CustomLayoutAlgorithm, LayoutAlgorithm, DynamicLayout, DynamicLayoutAttribute, LazyLayoutDirection, LazyLayoutHelper, LazyCustomLayoutAlgorithmOptions, LazyCustomLayoutAlgorithm, LazyLayoutAlgorithm, LazyDynamicLayout, LazyDynamicLayoutAttribute, ContainerReader, ContainerReaderAttribute, BreakpointOptions, LazyColumnLayout, LazyColumnLayoutAttribute, CustomComponentContext, IReusePool, IReusableInfo, PopupV2, PopupV2InitInfo, PopupV2Button, BackPressActionProposal, BaseGestureHandlingProposal, ClickActionProposal, GestureHandlingResolution, NoneActionProposal, PageSwitchActionProposal, ScrollActionProposal, SelectActionProposal, SmartGestureController, TargetedGestureProposal, LazyVWaterFlowLayout, LazyVWaterFlowLayoutAttribute, LazyWaterFlowLayoutAttribute, SelectionContainer, SelectionContainerAttribute, SelectionContainerInstance, SelectionContainerTextJoinStyle, SelectionContainerMenuOptions, SelectionContainerEditMenuOptions, OnMenuItemClickWithTextCallback, ComposeListItemV2, ContentItemV2, ContentItemV2Options, IconTypeV2, OperateButtonV2, OperateButtonV2Options, OperateCheckV2, OperateCheckV2Options, OperateIconV2, OperateIconV2Options, OperateItemV2, OperateItemV2Options, ComposeTitleBarV2, ComposeTitleBarV2MenuItem, ComposeTitleBarV2MenuItemParams, EditableLeftIconTypeV2, EditableTitleBarV2, EditableLeftIconV2, EditableLeftIconV2Options, EditableTitleV2, EditableTitleV2Options, EditableTitleBarItemV2, EditableTitleBarItemV2Options, EditableTitleBarMenuItemV2, EditableTitleBarMenuItemV2Options, EditableSaveButtonV2, EditableSaveButtonV2Options, EditableTitleBarStyleV2, EditableTitleBarStyleV2Options, MarginTypeV2, PromptOptionsV2, PromptOptionsV2Config, ExceptionPromptV2, SwipeRefresherV2, CallbackParamV2, NodeParamV2, TreeControllerV2, TreeListenerV2, TreeListenerManagerV2, TreeViewV2, DatePickerComponent, DatePickerComponentOptions, DisplayMode, DateMode, TimeFormat, DatePickerComponentResult };
```

### `openharmony/ets/kits/@kit.ImageKit.d.ts`

用途：Image Kit 桶导出

```ts
L19: import image from '@ohos.multimedia.image';
L20: import sendableImage from '@ohos.multimedia.sendableImage';
L21: import videoProcessingEngine from '@ohos.multimedia.videoProcessingEngine';
L22: export { image, sendableImage, videoProcessingEngine };
```

### `openharmony/ets/kits/@kit.AudioKit.d.ts`

用途：Audio Kit 桶导出

```ts
L19: import audio from '@ohos.multimedia.audio';
L20: import audioHaptic from '@ohos.multimedia.audioHaptic';
L21: import systemSoundManager from '@ohos.multimedia.systemSoundManager';
L22: import { AVVolumePanel, AVVolumePanelParameter } from '@ohos.multimedia.avVolumePanel';
L23: export { audio, audioHaptic, systemSoundManager, AVVolumePanel, AVVolumePanelParameter };
```

### `openharmony/ets/kits/@kit.CoreFileKit.d.ts`

用途：Core File Kit 桶导出

```ts
L19: import BackupExtensionAbility, { BundleVersion } from '@ohos.application.BackupExtensionAbility';
L20: import BackupExtensionContext from '@ohos.file.BackupExtensionContext';
L21: import cloudSync from '@ohos.file.cloudSync';
L22: import cloudSyncManager from '@ohos.file.cloudSyncManager';
L23: import Environment from '@ohos.file.environment';
L24: import fileAccess from '@ohos.file.fileAccess';
L25: import fileUri from '@ohos.file.fileuri';
L26: import fileIo, { ConflictFiles, FileFilter, Filter, Options, ReaderIteratorResult, WatchEvent, WatchEventListener, Watcher, ReadOptions, ReadTextOptions, WriteOptions, ListFileExtOptions, ListFileOptions, DfsListeners, TaskSignal } from '@ohos.file.fs';
L27: import hash from '@ohos.file.hash';
L28: import picker from '@ohos.file.picker';
L29: import securityLabel from '@ohos.file.securityLabel';
L30: import statfs from '@ohos.file.statvfs';
L31: import storageStatistics from '@ohos.file.storageStatistics';
L32: import keyManager from '@ohos.file.keyManager';
L33: import fileShare from '@ohos.fileshare';
L34: export { BackupExtensionAbility, BackupExtensionContext, BundleVersion, ConflictFiles, Environment, FileFilter, Filter, Options, ReaderIteratorResult, WatchEvent, WatchEventListener, Watcher, ReadOptions, ReadTextOptions, WriteOptions, ListFileExtOptions, ListFileOptions, cloudSync, cloudSyncManager, fileAccess, fileIo, fileShare, fileUri, hash, picker, securityLabel, statfs, storageStatistics, keyManager, DfsListeners, TaskSignal };
```

### `openharmony/ets/kits/@kit.NotificationKit.d.ts`

用途：Notification Kit 桶导出

```ts
L19: import notificationManager from '@ohos.notificationManager';
L20: import notificationExtensionSubscription from '@ohos.notificationExtensionSubscription';
L21: import NotificationSubscriberExtensionAbility from '@ohos.application.NotificationSubscriberExtensionAbility';
L22: import NotificationSubscriberExtensionContext from '@ohos.application.NotificationSubscriberExtensionContext';
L23: import Notification, { ActionResult, ShowNotificationOptions } from '@system.notification';
L24: export { ActionResult, Notification, ShowNotificationOptions, notificationManager, notificationExtensionSubscription, NotificationSubscriberExtensionAbility, NotificationSubscriberExtensionContext };
```

### `openharmony/ets/kits/@kit.NetworkKit.d.ts`

用途：Network Kit 桶导出

```ts
L19: import connection from '@ohos.net.connection';
L20: import http from '@ohos.net.http';
L21: import sharing from '@ohos.net.sharing';
L22: import webSocket from '@ohos.net.webSocket';
L23: import statistics from '@ohos.net.statistics';
L24: import networkSecurity from '@ohos.net.networkSecurity';
L25: import ethernet from '@ohos.net.ethernet';
L26: import mdns from '@ohos.net.mdns';
L27: import policy from '@ohos.net.policy';
L28: import socket from '@ohos.net.socket';
L29: import vpn from '@ohos.net.vpn';
L30: import vpnExtension from '@ohos.net.vpnExtension';
L31: import VpnExtensionAbility, { VpnExtensionContext } from '@ohos.app.ability.VpnExtensionAbility';
L32: import eap from '@ohos.net.eap';
L33: import netFirewall from '@ohos.net.netFirewall';
L34: export { connection, ethernet, http, mdns, policy, sharing, webSocket, socket, statistics, vpn, vpnExtension, networkSecurity, VpnExtensionAbility, VpnExtensionContext, eap, netFirewall };
```

### `openharmony/ets/kits/@kit.MediaLibraryKit.d.ts`

用途：Media Library Kit 桶导出

```ts
L19: import photoAccessHelper from '@ohos.file.photoAccessHelper';
L20: import sendablePhotoAccessHelper from '@ohos.file.sendablePhotoAccessHelper';
L21: import { MovingPhotoView, MovingPhotoViewController, MovingPhotoViewAttribute } from '@ohos.multimedia.movingphotoview';
L22: import { AlbumPickerComponent, AlbumPickerOptions, AlbumInfo, EmptyAreaClickCallback, AlbumPickerController } from '@ohos.file.AlbumPickerComponent';
L23: import { PhotoPickerComponent, PickerController, PickerOptions, DataType, BaseItemInfo, ItemInfo, PhotoBrowserInfo, AnimatorParams, MaxSelected, ItemType, ClickType, PickerOrientation, SelectMode, PickerColorMode, ReminderMode, MaxCountType, PhotoBrowserRange, PhotoBrowserUIElement, ItemsDeletedCallback, ExceedMaxSelectedCallback, CurrentAlbumDeletedCallback, videoPlayStateChangedCallback, MovingPhotoBadgeStateChangedCallback, UpdatablePickerConfigs, SingleLineConfig, BadgeConfig, PreselectedInfo, SaveMode, BadgeType, VideoPlayerState, ItemDisplayRatio, ScrollStopAtStartCallback, ItemClickedNotifyCallback, ScrollStopAtEndCallback, PhotoBrowserChangeStartCallback, PinchGridSwitchedCallback, ErrorCallback, ClickResult, PickerError } from '@ohos.file.PhotoPickerComponent';
L24: import { RecentPhotoComponent, RecentPhotoCheckResultCallback, RecentPhotoInfo, RecentPhotoCheckInfoCallback, RecentPhotoClickCallback, RecentPhotoOptions, PhotoSource } from '@ohos.file.RecentPhotoComponent';
L25: export { photoAccessHelper, sendablePhotoAccessHelper, MovingPhotoView, MovingPhotoViewController, MovingPhotoViewAttribute, PhotoPickerComponent, PickerController, PickerOptions, DataType, BaseItemInfo, ItemInfo, PhotoBrowserInfo, AnimatorParams, MaxSelected, ItemType, ClickType, PickerOrientation, SelectMode, PickerColorMode, ReminderMode, MaxCountType, PhotoBrowserRange, AlbumPickerComponent, AlbumPickerOptions, AlbumInfo, EmptyAreaClickCallback, AlbumPickerController, RecentPhotoComponent, RecentPhotoCheckResultCallback, RecentPhotoInfo, RecentPhotoCheckInfoCallback, RecentPhotoClickCallback, RecentPhotoOptions, PhotoSource, PhotoBrowserUIElement, ItemsDeletedCallback, ExceedMaxSelectedCallback, CurrentAlbumDeletedCallback, videoPlayStateChangedCallback, MovingPhotoBadgeStateChangedCallback, UpdatablePickerConfigs, SingleLineConfig, BadgeConfig, PreselectedInfo, SaveMode, BadgeType, VideoPlayerState, ItemDisplayRatio, ScrollStopAtStartCallback, ItemClickedNotifyCallback, ScrollStopAtEndCallback, PhotoBrowserChangeStartCallback, PinchGridSwitchedCallback, ErrorCallback, ClickResult, PickerError };
```

### `openharmony/ets/kits/@kit.BasicServicesKit.d.ts`

用途：Basic Services Kit 桶导出

```ts
L19: import appAccount from '@ohos.account.appAccount';
L20: import customConfig from '@ohos.customization.customConfig';
L21: import distributedAccount from '@ohos.account.distributedAccount';
L22: import osAccount from '@ohos.account.osAccount';
L23: import PrintExtensionAbility from '@ohos.app.ability.PrintExtensionAbility';
L24: import { AsyncCallback, BusinessError, Callback, ErrorCallback } from '@ohos.base';
L25: import batteryInfo from '@ohos.batteryInfo';
L26: import deviceAttest from '@ohos.deviceAttest';
L27: import deviceInfo from '@ohos.deviceInfo';
L28: import pasteboard from '@ohos.pasteboard';
L29: import power from '@ohos.power';
L30: import print from '@ohos.print';
L31: import scan from '@ohos.scan';
L32: import request from '@ohos.request';
L33: import cacheDownload from '@ohos.request.cacheDownload';
L34: import runningLock from '@ohos.runningLock';
L35: import screenLock from '@ohos.screenLock';
L36: import settings from '@ohos.settings';
L37: import systemDateTime from '@ohos.systemDateTime';
L38: import systemTime from '@ohos.systemTime';
L39: import thermal from '@ohos.thermal';
L40: import usb from '@ohos.usb';
L41: import usbManager from '@ohos.usbManager';
L42: import serialManager from '@ohos.usbManager.serial';
L43: import serial from '@ohos.busManager.serial';
L44: import wallpaper from '@ohos.wallpaper';
L45: import zlib from '@ohos.zlib';
L46: import commonEventManager from '@ohos.commonEventManager';
L47: import emitter from '@ohos.events.emitter';
L48: import Battery, { BatteryResponse, GetStatusOptions } from '@system.battery';
L49: import Brightness, { BrightnessModeResponse, BrightnessResponse, GetBrightnessModeOptions, GetBrightnessOptions, SetBrightnessModeOptions, SetBrightnessOptions, SetKeepScreenOnOptions } from '@system.brightness';
L50: import Device, { DeviceResponse, GetDeviceOptions } from '@system.device';
L51: import Request, { DownloadRequestOptions, DownloadResponse, OnDownloadCompleteOptions, OnDownloadCompleteResponse, RequestData, RequestFile, UploadRequestOptions, UploadResponse } from '@system.request';
L52: import systemLoad from '@ohos.resourceschedule.systemload';
L53: import SelectionExtensionAbility from '@ohos.selectionInput.SelectionExtensionAbility';
L54: import { PanelInfo, PanelType } from '@ohos.selectionInput.SelectionPanel';
L55: import selectionManager from '@ohos.selectionInput.selectionManager';
L56: import SelectionExtensionContext from '@ohos.selectionInput.SelectionExtensionContext';
L57: import { Available, SuppressWarnings, SuppressWarningsType } from '@ohos.annotation';
L58: import intelligentScene from '@ohos.intelligentScene';
L59: export { AsyncCallback, Battery, BatteryResponse, Brightness, BrightnessModeResponse, BrightnessResponse, BusinessError, Callback, Device, DeviceResponse, DownloadRequestOptions, DownloadResponse, ErrorCallback, GetBrightnessModeOptions, GetBrightnessOptions, GetDeviceOptions, GetStatusOptions, OnDownloadCompleteOptions, OnDownloadCompleteResponse, PrintExtensionAbility, Request, RequestData, RequestFile, SetBrightnessModeOptions, SetBrightnessOptions, SetKeepScreenOnOptions, UploadRequestOptions, UploadResponse, appAccount, batteryInfo, customConfig, deviceAttest, deviceInfo, distributedAccount, osAccount, pasteboard, power, print, scan, request, cacheDownload, runningLock, screenLock, settings, systemDateTime, systemTime, thermal, usb, usbManager, serialManager, wallpaper, zlib, commonEventManager, emitter, systemLoad, selectionManager, SelectionExtensionAbility, PanelInfo, PanelType, SelectionExtensionContext, Available, SuppressWarnings, SuppressWarningsType, intelligentScene, serial };
```

### `openharmony/ets/kits/@kit.BackgroundTasksKit.d.ts`

用途：Background Tasks Kit 桶导出

```ts
L19: import backgroundTaskManager from '@ohos.resourceschedule.backgroundTaskManager';
L20: import backgroundProcessManager from '@ohos.resourceschedule.backgroundProcessManager';
L21: import bundleState from '@ohos.bundleState';
L22: import reminderAgent from '@ohos.reminderAgent';
L23: import reminderAgentManager from '@ohos.reminderAgentManager';
L24: import deviceStandby from '@ohos.resourceschedule.deviceStandby';
L25: import usageStatistics from '@ohos.resourceschedule.usageStatistics';
L26: import workScheduler from '@ohos.resourceschedule.workScheduler';
L27: import WorkSchedulerExtensionAbility, { WorkSchedulerExtensionContext } from '@ohos.WorkSchedulerExtensionAbility';
L28: export { WorkSchedulerExtensionAbility, WorkSchedulerExtensionContext, backgroundTaskManager, bundleState, deviceStandby, reminderAgent, reminderAgentManager, usageStatistics, workScheduler, backgroundProcessManager };
```

### `openharmony/ets/kits/@kit.CalendarKit.d.ts`

用途：Calendar Kit 桶导出

```ts
L19: import calendarManager from '@ohos.calendarManager';
L20: export { calendarManager };
```

## Part 2 · 声明大纲（顶层声明 + 类/接口成员 + 行号 + JSDoc 关键标签）

### `hms/ets/api/@hms.ai.nlp.textProcessing.d.ts`

用途：实体抽取/分词签名与 @since
大小：9 KB（含类/接口成员）

```ts
  // @since 5.0.0(12) | @stagemodelonly | @syscap SystemCapability.AI.NaturalLanguage.TextProcessing
L16: declare namespace textProcessing {
  // @since 5.0.0(12) | @stagemodelonly | @syscap SystemCapability.AI.NaturalLanguage.TextProcessing
L24: export interface EntityConfig {
  // @since 5.0.0(12) | @stagemodelonly | @syscap SystemCapability.AI.NaturalLanguage.TextProcessing | @since 26.0.0
L52: export interface Entity {
  // @since 5.0.0(12) | @stagemodelonly | @syscap SystemCapability.AI.NaturalLanguage.TextProcessing
L60: text: string;
  // @since 5.0.0(12) | @stagemodelonly | @syscap SystemCapability.AI.NaturalLanguage.TextProcessing
L68: charOffset: number;
  // @since 5.0.0(12) | @stagemodelonly | @syscap SystemCapability.AI.NaturalLanguage.TextProcessing
L76: type: EntityType;
  // @since 5.0.0(12) | @stagemodelonly | @syscap SystemCapability.AI.NaturalLanguage.TextProcessing
L86: jsonObject: string;
  // @since 5.0.0(12) | @stagemodelonly | @syscap SystemCapability.AI.NaturalLanguage.TextProcessing
L95: export interface WordSegment {
  // @since 5.0.0(12) | @stagemodelonly | @syscap SystemCapability.AI.NaturalLanguage.TextProcessing
L103: word: string;
  // @since 5.0.0(12) | @stagemodelonly | @syscap SystemCapability.AI.NaturalLanguage.TextProcessing
L112: wordTag: string;
  // @since 5.0.0(12) | @stagemodelonly | @syscap SystemCapability.AI.NaturalLanguage.TextProcessing
L129: function getWordSegment(text: string): Promise<Array<WordSegment>>;
  // @since 5.0.0(12) | @stagemodelonly | @syscap SystemCapability.AI.NaturalLanguage.TextProcessing
L147: function getEntity(text: string, entityConfig?: EntityConfig): Promise<Array<Entity>>;
  // @since 5.0.0(12) | @stagemodelonly | @syscap SystemCapability.AI.NaturalLanguage.TextProcessing
L160: function init(): Promise<boolean>;
  // @since 5.0.0(12) | @stagemodelonly | @syscap SystemCapability.AI.NaturalLanguage.TextProcessing
L173: function release(): Promise<boolean>;
  // @since 5.0.0(12) | @stagemodelonly | @syscap SystemCapability.AI.NaturalLanguage.TextProcessing
L182: export enum EntityType {
```

### `hms/ets/api/@hms.ai.speechRecognizer.d.ts`

用途：语音识别 createEngine/StartParams/writeAudio
大小：20 KB（含类/接口成员）

```ts
  // @since 4.1.0(11) | @stagemodelonly | @syscap SystemCapability.AI.SpeechRecognizer
L20: declare namespace speechRecognizer {
  // @since 4.1.0(11) | @stagemodelonly | @syscap SystemCapability.AI.SpeechRecognizer
L35: function createEngine(createEngineParams: CreateEngineParams, callback: AsyncCallback<SpeechRecognitionEngine>): void;
  // @since 4.1.0(11) | @stagemodelonly | @syscap SystemCapability.AI.SpeechRecognizer
L50: function createEngine(createEngineParams: CreateEngineParams): Promise<SpeechRecognitionEngine>;
  // @since 4.1.0(11) | @stagemodelonly | @syscap SystemCapability.AI.SpeechRecognizer
L61: export interface SpeechRecognitionEngine {
  // @since 4.1.0(11) | @stagemodelonly | @syscap SystemCapability.AI.SpeechRecognizer
L71: setListener(listener: RecognitionListener): void;
  // @since 4.1.0(11) | @stagemodelonly | @syscap SystemCapability.AI.SpeechRecognizer
L85: listLanguages(params: LanguageQuery, callback: AsyncCallback<Array<string>>): void;
  // @since 4.1.0(11) | @stagemodelonly | @syscap SystemCapability.AI.SpeechRecognizer
L99: listLanguages(params: LanguageQuery): Promise<Array<string>>;
  // @since 4.1.0(11) | @stagemodelonly | @syscap SystemCapability.AI.SpeechRecognizer
L112: startListening(params: StartParams): void;
  // @since 4.1.0(11) | @stagemodelonly | @syscap SystemCapability.AI.SpeechRecognizer
L132: writeAudio(sessionId: string, audio: Uint8Array): void;
  // @since 4.1.0(11) | @stagemodelonly | @syscap SystemCapability.AI.SpeechRecognizer
L146: finish(sessionId: string): void;
  // @since 4.1.0(11) | @stagemodelonly | @syscap SystemCapability.AI.SpeechRecognizer
L160: cancel(sessionId: string): void;
  // @since 4.1.0(11) | @stagemodelonly | @syscap SystemCapability.AI.SpeechRecognizer
L170: isBusy(): boolean;
  // @since 4.1.0(11) | @stagemodelonly | @syscap SystemCapability.AI.SpeechRecognizer
L178: shutdown(): void;
  // @since 4.1.0(11) | @stagemodelonly | @syscap SystemCapability.AI.SpeechRecognizer
L188: export interface RecognitionListener {
  // @since 4.1.0(11) | @stagemodelonly | @syscap SystemCapability.AI.SpeechRecognizer
L201: onStart(sessionId: string, eventMessage: string): void;
  // @since 4.1.0(11) | @stagemodelonly | @syscap SystemCapability.AI.SpeechRecognizer
L217: onEvent(sessionId: string, eventCode: number, eventMessage: string): void;
  // @since 4.1.0(11) | @stagemodelonly | @syscap SystemCapability.AI.SpeechRecognizer
L228: onResult(sessionId: string, result: SpeechRecognitionResult): void;
  // @since 4.1.0(11) | @stagemodelonly | @syscap SystemCapability.AI.SpeechRecognizer
L241: onComplete(sessionId: string, eventMessage: string): void;
  // @since 4.1.0(11) | @stagemodelonly | @syscap SystemCapability.AI.SpeechRecognizer
L254: onError(sessionId: string, errorCode: number, errorMessage: string): void;
  // @since 4.1.0(11) | @stagemodelonly | @syscap SystemCapability.AI.SpeechRecognizer
L263: export interface CreateEngineParams {
  // @since 4.1.0(11) | @stagemodelonly | @syscap SystemCapability.AI.SpeechRecognizer
L271: language: string;
  // @since 4.1.0(11) | @stagemodelonly | @syscap SystemCapability.AI.SpeechRecognizer
L281: online: number;
  // @since 4.1.0(11) | @stagemodelonly | @syscap SystemCapability.AI.SpeechRecognizer
L313: export interface LanguageQuery {
  // @since 4.1.0(11) | @stagemodelonly | @syscap SystemCapability.AI.SpeechRecognizer
L325: sessionId: string;
  // @since 4.1.0(11) | @stagemodelonly | @syscap SystemCapability.AI.SpeechRecognizer
L344: export interface StartParams {
  // @since 4.1.0(11) | @stagemodelonly | @syscap SystemCapability.AI.SpeechRecognizer
L356: sessionId: string;
  // @since 4.1.0(11) | @stagemodelonly | @syscap SystemCapability.AI.SpeechRecognizer
L364: audioInfo: AudioInfo;
  // @since 4.1.0(11) | @stagemodelonly | @syscap SystemCapability.AI.SpeechRecognizer
L383: export interface AudioInfo {
  // @since 4.1.0(11) | @stagemodelonly | @syscap SystemCapability.AI.SpeechRecognizer
L393: audioType: string;
  // @since 4.1.0(11) | @stagemodelonly | @syscap SystemCapability.AI.SpeechRecognizer
L403: sampleRate: number;
  // @since 4.1.0(11) | @stagemodelonly | @syscap SystemCapability.AI.SpeechRecognizer
L413: soundChannel: number;
  // @since 4.1.0(11) | @stagemodelonly | @syscap SystemCapability.AI.SpeechRecognizer
L423: sampleBit: number;
  // @since 4.1.0(11) | @stagemodelonly | @syscap SystemCapability.AI.SpeechRecognizer
L442: export interface SpeechRecognitionResult {
  // @since 4.1.0(11) | @stagemodelonly | @syscap SystemCapability.AI.SpeechRecognizer
L453: isFinal: boolean;
  // @since 4.1.0(11) | @stagemodelonly | @syscap SystemCapability.AI.SpeechRecognizer
L464: isLast: boolean;
  // @since 4.1.0(11) | @stagemodelonly | @syscap SystemCapability.AI.SpeechRecognizer
L472: result: string;
```

### `hms/ets/api/@hms.ai.textToSpeech.d.ts`

用途：语音合成
大小：39 KB（含类/接口成员）

```ts
  // @since 4.1.0(11) | @atomicservice [since 6.1.1(24)] | @stagemodelonly | @syscap SystemCapability.AI.TextToSpeech
L23: declare namespace textToSpeech {
  // @since 4.1.0(11) | @atomicservice [since 6.1.1(24)] | @stagemodelonly | @syscap SystemCapability.AI.TextToSpeech
L40: function createEngine(createEngineParams: CreateEngineParams, callback: AsyncCallback<TextToSpeechEngine>): void;
  // @since 4.1.0(11) | @atomicservice [since 6.1.1(24)] | @stagemodelonly | @syscap SystemCapability.AI.TextToSpeech
L57: function createEngine(createEngineParams: CreateEngineParams): Promise<TextToSpeechEngine>;
  // @since 4.1.0(11) | @atomicservice [since 6.1.1(24)] | @stagemodelonly | @syscap SystemCapability.AI.TextToSpeech
L69: export interface TextToSpeechEngine {
  // @since 4.1.0(11) | @atomicservice [since 6.1.1(24)] | @stagemodelonly | @syscap SystemCapability.AI.TextToSpeech
L79: setListener(listener: SpeakListener): void;
  // @since 4.1.0(11) | @atomicservice [since 6.1.1(24)] | @stagemodelonly | @syscap SystemCapability.AI.TextToSpeech
L98: speak(text: string, speakParams: SpeakParams): void;
  // @since 4.1.0(11) | @atomicservice [since 6.1.1(24)] | @stagemodelonly | @syscap SystemCapability.AI.TextToSpeech
L111: listVoices(params: VoiceQuery, callback: AsyncCallback<Array<VoiceInfo>>): void;
  // @since 4.1.0(11) | @atomicservice [since 6.1.1(24)] | @stagemodelonly | @syscap SystemCapability.AI.TextToSpeech
L124: listVoices(params: VoiceQuery): Promise<Array<VoiceInfo>>;
  // @since 4.1.0(11) | @atomicservice [since 6.1.1(24)] | @stagemodelonly | @syscap SystemCapability.AI.TextToSpeech
L135: stop(): void;
  // @since 4.1.0(11) | @atomicservice [since 6.1.1(24)] | @stagemodelonly | @syscap SystemCapability.AI.TextToSpeech
L149: isBusy(): boolean;
  // @since 4.1.0(11) | @atomicservice [since 6.1.1(24)] | @stagemodelonly | @syscap SystemCapability.AI.TextToSpeech
L158: shutdown(): void;
  // @since 4.1.0(11) | @atomicservice [since 6.1.1(24)] | @stagemodelonly | @syscap SystemCapability.AI.TextToSpeech
L169: export interface SpeakListener {
  // @since 4.1.0(11) | @atomicservice [since 6.1.1(24)] | @stagemodelonly | @syscap SystemCapability.AI.TextToSpeech
L182: onStart(requestId: string, response: StartResponse): void;
  // @since 4.1.0(11) | @atomicservice [since 6.1.1(24)] | @stagemodelonly | @syscap SystemCapability.AI.TextToSpeech
L194: onComplete(requestId: string, response: CompleteResponse): void;
  // @since 4.1.0(11) | @atomicservice [since 6.1.1(24)] | @stagemodelonly | @syscap SystemCapability.AI.TextToSpeech
L206: onStop(requestId: string, response: StopResponse): void;
  // @since 4.1.0(11) | @atomicservice [since 6.1.1(24)] | @stagemodelonly | @syscap SystemCapability.AI.TextToSpeech
L220: onError(requestId: string, errorCode: number, errorMessage: string): void;
  // @since 4.1.0(11) | @atomicservice [since 6.1.1(24)] | @stagemodelonly | @syscap SystemCapability.AI.TextToSpeech
L252: export interface CreateEngineParams {
  // @since 4.1.0(11) | @atomicservice [since 6.1.1(24)] | @stagemodelonly | @syscap SystemCapability.AI.TextToSpeech
L265: language: string;
  // @since 4.1.0(11) | @atomicservice [since 6.1.1(24)] | @stagemodelonly | @syscap SystemCapability.AI.TextToSpeech
L279: person: number;
  // @since 4.1.0(11) | @atomicservice [since 6.1.1(24)] | @stagemodelonly | @syscap SystemCapability.AI.TextToSpeech
L290: online: number;
  // @since 4.1.0(11) | @atomicservice [since 6.1.1(24)] | @stagemodelonly | @syscap SystemCapability.AI.TextToSpeech
L332: export interface SpeakParams {
  // @since 4.1.0(11) | @atomicservice [since 6.1.1(24)] | @stagemodelonly | @syscap SystemCapability.AI.TextToSpeech
L343: requestId: string;
  // @since 4.1.0(11) | @atomicservice [since 6.1.1(24)] | @stagemodelonly | @syscap SystemCapability.AI.TextToSpeech
L386: export interface VoiceQuery {
  // @since 4.1.0(11) | @atomicservice [since 6.1.1(24)] | @stagemodelonly | @syscap SystemCapability.AI.TextToSpeech
L397: requestId: string;
  // @since 4.1.0(11) | @atomicservice [since 6.1.1(24)] | @stagemodelonly | @syscap SystemCapability.AI.TextToSpeech
L408: online: number;
  // @since 4.1.0(11) | @atomicservice [since 6.1.1(24)] | @stagemodelonly | @syscap SystemCapability.AI.TextToSpeech
L450: export interface VoiceInfo {
  // @since 4.1.0(11) | @atomicservice [since 6.1.1(24)] | @stagemodelonly | @syscap SystemCapability.AI.TextToSpeech
L463: language: string;
  // @since 4.1.0(11) | @atomicservice [since 6.1.1(24)] | @stagemodelonly | @syscap SystemCapability.AI.TextToSpeech
L477: person: number;
  // @since 4.1.0(11) | @atomicservice [since 6.1.1(24)] | @stagemodelonly | @syscap SystemCapability.AI.TextToSpeech
L488: style: string;
  // @since 4.1.0(11) | @atomicservice [since 6.1.1(24)] | @stagemodelonly | @syscap SystemCapability.AI.TextToSpeech
L500: gender: string;
  // @since 4.1.0(11) | @atomicservice [since 6.1.1(24)] | @stagemodelonly | @syscap SystemCapability.AI.TextToSpeech
L509: description: string;
  // @since 4.1.0(11) | @atomicservice [since 6.1.1(24)] | @stagemodelonly | @syscap SystemCapability.AI.TextToSpeech | @since 5.1.1(19)
L532: export interface StartResponse {
  // @since 4.1.0(11) | @atomicservice [since 6.1.1(24)] | @stagemodelonly | @syscap SystemCapability.AI.TextToSpeech
L541: audioType: string;
  // @since 4.1.0(11) | @atomicservice [since 6.1.1(24)] | @stagemodelonly | @syscap SystemCapability.AI.TextToSpeech
L550: sampleRate: number;
  // @since 4.1.0(11) | @atomicservice [since 6.1.1(24)] | @stagemodelonly | @syscap SystemCapability.AI.TextToSpeech
L559: sampleBit: number;
  // @since 4.1.0(11) | @atomicservice [since 6.1.1(24)] | @stagemodelonly | @syscap SystemCapability.AI.TextToSpeech
L568: audioChannel: number;
  // @since 4.1.0(11) | @atomicservice [since 6.1.1(24)] | @stagemodelonly | @syscap SystemCapability.AI.TextToSpeech
L577: compressRate: number;
  // @since 4.1.0(11) | @atomicservice [since 6.1.1(24)] | @stagemodelonly | @syscap SystemCapability.AI.TextToSpeech
L587: export interface StopResponse {
  // @since 4.1.0(11) | @atomicservice [since 6.1.1(24)] | @stagemodelonly | @syscap SystemCapability.AI.TextToSpeech
L599: type: number;
  // @since 4.1.0(11) | @atomicservice [since 6.1.1(24)] | @stagemodelonly | @syscap SystemCapability.AI.TextToSpeech
L610: message: string;
  // @since 4.1.0(11) | @atomicservice [since 6.1.1(24)] | @stagemodelonly | @syscap SystemCapability.AI.TextToSpeech
L620: export interface CompleteResponse {
  // @since 4.1.0(11) | @atomicservice [since 6.1.1(24)] | @stagemodelonly | @syscap SystemCapability.AI.TextToSpeech
L632: type: number;
  // @since 4.1.0(11) | @atomicservice [since 6.1.1(24)] | @stagemodelonly | @syscap SystemCapability.AI.TextToSpeech
L643: message: string;
  // @since 4.1.0(11) | @atomicservice [since 6.1.1(24)] | @stagemodelonly | @syscap SystemCapability.AI.TextToSpeech
L653: export interface SynthesisResponse {
  // @since 4.1.0(11) | @atomicservice [since 6.1.1(24)] | @stagemodelonly | @syscap SystemCapability.AI.TextToSpeech
L666: sequence: number;
  // @since 4.1.0(11) | @atomicservice [since 6.1.1(24)] | @stagemodelonly | @syscap SystemCapability.AI.TextToSpeech
L675: audioType: string;
  // @since 5.1.1(19) | @atomicservice [since 6.1.1(24)] | @stagemodelonly | @syscap SystemCapability.AI.TextToSpeech | @since 4.1.0(11)
L689: function listVoices(queryParams: VoiceQuery): Promise<VoiceInfo[]>;
  // @since 5.1.1(19) | @atomicservice [since 6.1.1(24)] | @stagemodelonly | @syscap SystemCapability.AI.TextToSpeech
L705: function downloadVoice(downloadParams: VoiceDownload, callback: AsyncCallback<DownloadResponse>): void;
  // @since 5.1.1(19) | @atomicservice [since 6.1.1(24)] | @stagemodelonly | @syscap SystemCapability.AI.TextToSpeech
L718: type OnDataCallback = (requestId: string, audio: ArrayBuffer, response: SynthesisResponse) => void;
  // @since 5.1.1(19) | @atomicservice [since 6.1.1(24)] | @stagemodelonly | @syscap SystemCapability.AI.TextToSpeech
L727: export interface VoiceDownload {
  // @since 5.1.1(19) | @atomicservice [since 6.1.1(24)] | @stagemodelonly | @syscap SystemCapability.AI.TextToSpeech
L738: requestId: string;
  // @since 5.1.1(19) | @atomicservice [since 6.1.1(24)] | @stagemodelonly | @syscap SystemCapability.AI.TextToSpeech
L751: language: string;
  // @since 5.1.1(19) | @atomicservice [since 6.1.1(24)] | @stagemodelonly | @syscap SystemCapability.AI.TextToSpeech
L764: person: number;
  // @since 5.1.1(19) | @atomicservice [since 6.1.1(24)] | @stagemodelonly | @syscap SystemCapability.AI.TextToSpeech
L777: style: string;
  // @since 5.1.1(19) | @atomicservice [since 6.1.1(24)] | @stagemodelonly | @syscap SystemCapability.AI.TextToSpeech
L787: export interface DownloadResponse {
  // @since 5.1.1(19) | @atomicservice [since 6.1.1(24)] | @stagemodelonly | @syscap SystemCapability.AI.TextToSpeech
L798: requestId: string;
  // @since 5.1.1(19) | @atomicservice [since 6.1.1(24)] | @stagemodelonly | @syscap SystemCapability.AI.TextToSpeech
L810: on(type: 'start', callback: Callback<string>): void;
  // @since 5.1.1(19) | @atomicservice [since 6.1.1(24)] | @stagemodelonly | @syscap SystemCapability.AI.TextToSpeech
L822: off(type: 'start', callback?: Callback<string>): void;
  // @since 5.1.1(19) | @atomicservice [since 6.1.1(24)] | @stagemodelonly | @syscap SystemCapability.AI.TextToSpeech
L833: on(type: 'progress', callback: Callback<string>): void;
  // @since 5.1.1(19) | @atomicservice [since 6.1.1(24)] | @stagemodelonly | @syscap SystemCapability.AI.TextToSpeech
L845: off(type: 'progress', callback?: Callback<string>): void;
  // @since 5.1.1(19) | @atomicservice [since 6.1.1(24)] | @stagemodelonly | @syscap SystemCapability.AI.TextToSpeech
L858: on(type: 'complete', callback: Callback<VoiceInfo>): void;
  // @since 5.1.1(19) | @atomicservice [since 6.1.1(24)] | @stagemodelonly | @syscap SystemCapability.AI.TextToSpeech
L870: off(type: 'complete', callback?: Callback<VoiceInfo>): void;
  // @since 5.1.1(19) | @atomicservice [since 6.1.1(24)] | @stagemodelonly | @syscap SystemCapability.AI.TextToSpeech
L882: on(type: 'cancel', callback: Callback<string>): void;
  // @since 5.1.1(19) | @atomicservice [since 6.1.1(24)] | @stagemodelonly | @syscap SystemCapability.AI.TextToSpeech
L894: off(type: 'cancel', callback?: Callback<string>): void;
  // @since 5.1.1(19) | @atomicservice [since 6.1.1(24)] | @stagemodelonly | @syscap SystemCapability.AI.TextToSpeech
L905: on(type: 'error', callback: ErrorCallback<BusinessError>): void;
  // @since 5.1.1(19) | @atomicservice [since 6.1.1(24)] | @stagemodelonly | @syscap SystemCapability.AI.TextToSpeech
L917: off(type: 'error', callback?: ErrorCallback<BusinessError>): void;
```

### `hms/ets/api/@hms.ai.ocr.textRecognition.d.ts`

用途：文字识别签名与 VisionInfo
大小：12 KB（含类/接口成员）

```ts
  // @since 4.0.0(10) | @stagemodelonly | @syscap SystemCapability.AI.OCR.TextRecognition
L35: declare namespace textRecognition {
  // @since 4.0.0(10) | @stagemodelonly | @syscap SystemCapability.AI.OCR.TextRecognition
L43: export interface TextRecognitionConfiguration {
  // @since 4.0.0(10) | @stagemodelonly | @syscap SystemCapability.AI.OCR.TextRecognition
L68: export interface VisionInfo {
  // @since 4.0.0(10) | @stagemodelonly | @syscap SystemCapability.AI.OCR.TextRecognition
L79: readonly pixelMap: image.PixelMap;
  // @since 4.0.0(10) | @stagemodelonly | @syscap SystemCapability.AI.OCR.TextRecognition
L88: export interface PixelPoint {
  // @since 4.0.0(10) | @stagemodelonly | @syscap SystemCapability.AI.OCR.TextRecognition
L96: readonly x: number;
  // @since 4.0.0(10) | @stagemodelonly | @syscap SystemCapability.AI.OCR.TextRecognition
L104: readonly y: number;
  // @since 4.0.0(10) | @stagemodelonly | @syscap SystemCapability.AI.OCR.TextRecognition
L113: export interface TextWord {
  // @since 4.0.0(10) | @stagemodelonly | @syscap SystemCapability.AI.OCR.TextRecognition
L121: readonly value: string;
  // @since 4.0.0(10) | @stagemodelonly | @syscap SystemCapability.AI.OCR.TextRecognition
L129: readonly cornerPoints: Array<PixelPoint>;
  // @since 4.0.0(10) | @stagemodelonly | @syscap SystemCapability.AI.OCR.TextRecognition
L138: export interface TextLine {
  // @since 4.0.0(10) | @stagemodelonly | @syscap SystemCapability.AI.OCR.TextRecognition
L146: readonly value: string;
  // @since 4.0.0(10) | @stagemodelonly | @syscap SystemCapability.AI.OCR.TextRecognition
L154: readonly cornerPoints: Array<PixelPoint>;
  // @since 4.0.0(10) | @stagemodelonly | @syscap SystemCapability.AI.OCR.TextRecognition
L162: readonly words: Array<TextWord>;
  // @since 4.0.0(10) | @stagemodelonly | @syscap SystemCapability.AI.OCR.TextRecognition
L171: export interface TextBlock {
  // @since 4.0.0(10) | @stagemodelonly | @syscap SystemCapability.AI.OCR.TextRecognition
L179: readonly value: string;
  // @since 4.0.0(10) | @stagemodelonly | @syscap SystemCapability.AI.OCR.TextRecognition
L187: readonly lines: Array<TextLine>;
  // @since 4.0.0(10) | @stagemodelonly | @syscap SystemCapability.AI.OCR.TextRecognition
L196: export interface TextRecognitionResult {
  // @since 4.0.0(10) | @stagemodelonly | @syscap SystemCapability.AI.OCR.TextRecognition
L204: readonly value: string;
  // @since 4.0.0(10) | @stagemodelonly | @syscap SystemCapability.AI.OCR.TextRecognition
L212: readonly blocks: Array<TextBlock>;
  // @since 4.0.0(10) | @stagemodelonly | @syscap SystemCapability.AI.OCR.TextRecognition
L227: function recognizeText(visionInfo: VisionInfo, callback: AsyncCallback<TextRecognitionResult>): void;
  // @since 4.0.0(10) | @stagemodelonly | @syscap SystemCapability.AI.OCR.TextRecognition
L243: function recognizeText(visionInfo: VisionInfo, configuration?: TextRecognitionConfiguration): Promise<TextRecognitionResult>;
  // @since 4.0.0(10) | @stagemodelonly | @syscap SystemCapability.AI.OCR.TextRecognition
L260: function recognizeText(visionInfo: VisionInfo, configuration: TextRecognitionConfiguration, callback: AsyncCallback<TextRecognitionResult>): void;
  // @since 4.0.0(10) | @stagemodelonly | @syscap SystemCapability.AI.OCR.TextRecognition
L273: function getSupportedLanguages(): Promise<Array<string>>;
  // @since 4.0.0(10) | @stagemodelonly | @syscap SystemCapability.AI.OCR.TextRecognition
L286: function getSupportedLanguages(callback: AsyncCallback<Array<string>>): void;
  // @since 5.0.0(12) | @stagemodelonly | @syscap SystemCapability.AI.OCR.TextRecognition
L296: function init(): Promise<boolean>;
  // @since 5.0.0(12) | @stagemodelonly | @syscap SystemCapability.AI.OCR.TextRecognition
L305: function release(): Promise<void>;
```

### `hms/ets/api/@hms.ai.insightIntent.d.ts`

用途：意图框架（无抽取类接口的依据）
大小：12 KB（含类/接口成员）

```ts
  // @since 4.0.0(10) | @atomicservice [since 5.0.0(12)] | @stagemodelonly | @syscap SystemCapability.AI.InsightIntent
L19: declare namespace insightIntent {
  // @since 4.0.0(10) | @atomicservice [since 5.0.0(12)] | @stagemodelonly | @syscap SystemCapability.AI.InsightIntent
L41: function shareIntent(context: common.BaseContext, intents: InsightIntent[], callback: AsyncCallback<void>): void;
  // @since 4.0.0(10) | @atomicservice [since 5.0.0(12)] | @stagemodelonly | @syscap SystemCapability.AI.InsightIntent
L63: function shareIntent(context: common.BaseContext, intents: InsightIntent[]): Promise<void>;
  // @since 4.0.0(10) | @atomicservice [since 5.0.0(12)] | @stagemodelonly | @syscap SystemCapability.AI.InsightIntent
L81: function deleteIntent(context: common.BaseContext, intentName: string, identifiers: string[], callback: AsyncCallback<void>): void;
  // @since 4.0.0(10) | @atomicservice [since 5.0.0(12)] | @stagemodelonly | @syscap SystemCapability.AI.InsightIntent
L97: function deleteIntent(context: common.BaseContext, intentName: string, callback: AsyncCallback<void>): void;
  // @since 4.0.0(10) | @atomicservice [since 5.0.0(12)] | @stagemodelonly | @syscap SystemCapability.AI.InsightIntent
L115: function deleteIntent(context: common.BaseContext, intentName: string, identifiers?: string[]): Promise<void>;
  // @since 4.0.0(10) | @atomicservice [since 5.0.0(12)] | @stagemodelonly | @syscap SystemCapability.AI.InsightIntent
L131: function deleteEntity(context: common.BaseContext, entityName: string, entityIds: string[], callback: AsyncCallback<void>): void;
  // @since 4.0.0(10) | @atomicservice [since 5.0.0(12)] | @stagemodelonly | @syscap SystemCapability.AI.InsightIntent
L147: function deleteEntity(context: common.BaseContext, entityName: string, entityIds: string[]): Promise<void>;
  // @since 5.0.0(12) | @atomicservice | @stagemodelonly | @syscap SystemCapability.AI.InsightIntent
L168: function getSid(context: common.BaseContext, renew: boolean): Promise<string>;
  // @since 4.0.0(10) | @atomicservice [since 5.0.0(12)] | @stagemodelonly | @syscap SystemCapability.AI.InsightIntent
L177: interface InsightIntent {
  // @since 4.0.0(10) | @atomicservice [since 5.0.0(12)] | @stagemodelonly | @syscap SystemCapability.AI.InsightIntent
L186: intentName: string;
  // @since 4.0.0(10) | @atomicservice [since 5.0.0(12)] | @stagemodelonly | @syscap SystemCapability.AI.InsightIntent
L195: intentVersion: string;
  // @since 4.0.0(10) | @atomicservice [since 5.0.0(12)] | @stagemodelonly | @syscap SystemCapability.AI.InsightIntent
L204: identifier: string;
  // @since 4.0.0(10) | @atomicservice [since 5.0.0(12)] | @stagemodelonly | @syscap SystemCapability.AI.InsightIntent
L213: intentActionInfo: IntentActionInfo;
  // @since 4.0.0(10) | @atomicservice [since 5.0.0(12)] | @stagemodelonly | @syscap SystemCapability.AI.InsightIntent
L222: intentEntityInfo: IntentEntityInfo;
  // @since 5.0.0(12) | @atomicservice | @stagemodelonly | @syscap SystemCapability.AI.InsightIntent | @since 4.0.0(10) | @atomicservice [since 5.0.0(12)]
L232: interface IntentEntityInfo {
  // @since 5.0.0(12) | @atomicservice | @stagemodelonly | @syscap SystemCapability.AI.InsightIntent
L241: entityId: string;
  // @since 5.0.0(12) | @atomicservice | @stagemodelonly | @syscap SystemCapability.AI.InsightIntent
L250: entityName: string;
  // @since 5.0.0(12) | @atomicservice | @stagemodelonly | @syscap SystemCapability.AI.InsightIntent
L269: interface IntentActionInfo {
```

### `hms/ets/api/@hms.ai.A2A.d.ts`

用途：Agent 间通信
大小：18 KB（含类/接口成员）

```ts
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.AI.Agent.AgentKit
L18: export enum Role {
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.AI.Agent.AgentKit
L50: export enum TaskState {
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.AI.Agent.AgentKit
L131: export interface Part {
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.AI.Agent.AgentKit
L201: export interface Message {
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.AI.Agent.AgentKit
L209: messageId: string;
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.AI.Agent.AgentKit
L217: role: Role;
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.AI.Agent.AgentKit
L225: parts: Part[];
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.AI.Agent.AgentKit
L275: export interface Artifact {
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.AI.Agent.AgentKit
L283: artifactId: string;
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.AI.Agent.AgentKit
L291: parts: Part[];
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.AI.Agent.AgentKit
L333: export interface TaskStatus {
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.AI.Agent.AgentKit
L341: state: TaskState;
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.AI.Agent.AgentKit
L368: export interface Task {
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.AI.Agent.AgentKit
L376: id: string;
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.AI.Agent.AgentKit
L384: contextId: string;
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.AI.Agent.AgentKit
L392: status: TaskStatus;
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.AI.Agent.AgentKit
L427: export type OnDataCallback = (method: AgentOperation, context: RequestContext) => void;
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.AI.Agent.AgentKit
L441: export function createA2AServer(agentCard: common.AgentCard, onData: OnDataCallback, want?: Want): Server;
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.AI.Agent.AgentKit
L450: export type ProxySender = (data: string) => void;
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.AI.Agent.AgentKit
L458: export interface Server {
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.AI.Agent.AgentKit
L466: start(): void;
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.AI.Agent.AgentKit
L474: stop(): void;
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.AI.Agent.AgentKit
L484: onMessage(data: string, sender: ProxySender): void;
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.AI.Agent.AgentKit
L494: onAuth(data: string): string;
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.AI.Agent.AgentKit
L505: updateStatus(taskId: string, status: TaskStatus): void;
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.AI.Agent.AgentKit
L515: addArtifact(taskId: string, taskArtifactParam: TaskArtifactParam): void;
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.AI.Agent.AgentKit
L524: export enum AgentOperation {
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.AI.Agent.AgentKit
L565: export interface RequestContext {
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.AI.Agent.AgentKit
L574: getAgentId(): string | undefined;
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.AI.Agent.AgentKit
L583: getClientSessionId(): string | undefined;
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.AI.Agent.AgentKit
L593: getUserInput(delimiter?: string): string;
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.AI.Agent.AgentKit
L602: getMessage(): Message | undefined;
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.AI.Agent.AgentKit
L611: getRelatedTasks(): Task[];
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.AI.Agent.AgentKit
L620: getCurrentTask(): Task | undefined;
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.AI.Agent.AgentKit
L629: getTaskId(): string | undefined;
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.AI.Agent.AgentKit
L638: getContextId(): string | undefined;
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.AI.Agent.AgentKit
L647: getMetadata(): object;
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.AI.Agent.AgentKit
L656: export interface TaskArtifactParam {
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.AI.Agent.AgentKit
L664: parts: Part[];
```

### `hms/ets/api/@hms.collaboration.systemShare.d.ts`

用途：分享发起侧签名
大小：32 KB（含类/接口成员）

```ts
  // @since 4.1.0(11) | @stagemodelonly | @syscap SystemCapability.Collaboration.SystemShare
L23: declare namespace systemShare {
  // @since 4.1.0(11) | @stagemodelonly | @syscap SystemCapability.Collaboration.SystemShare
L38: class SharedData {
  // @since 4.1.0(11) | @stagemodelonly | @syscap SystemCapability.Collaboration.SystemShare
L48: constructor(record: SharedRecord);
  // @since 4.1.0(11) | @stagemodelonly | @syscap SystemCapability.Collaboration.SystemShare
L59: addRecord(record: SharedRecord): void;
  // @since 4.1.0(11) | @stagemodelonly | @syscap SystemCapability.Collaboration.SystemShare
L68: getRecords(): Array<SharedRecord>;
  // @since 4.1.0(11) | @stagemodelonly | @syscap SystemCapability.Collaboration.SystemShare
L77: interface SharedRecord {
  // @since 4.1.0(11) | @stagemodelonly | @syscap SystemCapability.Collaboration.SystemShare
L87: utd: string;
  // @since 6.1.0(23) | @stagemodelonly | @syscap SystemCapability.Collaboration.SystemShare | @since 4.1.0(11) | @since 5.0.0(12)
L184: enum RevisitShareRecordType {
  // @since 6.1.0(23) | @stagemodelonly | @syscap SystemCapability.Collaboration.SystemShare
L201: enum ReadingShareRecordStyle {
  // @since 6.1.0(23) | @stagemodelonly | @syscap SystemCapability.Collaboration.SystemShare
L226: interface RevisitShareRecordData {
  // @since 6.1.0(23) | @stagemodelonly | @syscap SystemCapability.Collaboration.SystemShare
L234: revisitShareRecordType: RevisitShareRecordType;
  // @since 6.1.0(23) | @stagemodelonly | @syscap SystemCapability.Collaboration.SystemShare
L242: generatedImageUri: string;
  // @since 6.1.0(23) | @stagemodelonly | @syscap SystemCapability.Collaboration.SystemShare
L251: interface ReadingExtendedShareRecordData extends RevisitShareRecordData {
  // @since 6.1.0(23) | @stagemodelonly | @syscap SystemCapability.Collaboration.SystemShare
L259: sourceTitle: string;
  // @since 6.1.0(23) | @stagemodelonly | @syscap SystemCapability.Collaboration.SystemShare
L267: appLink: string;
  // @since 4.1.0(11) | @stagemodelonly | @syscap SystemCapability.Collaboration.SystemShare | @since 6.1.0(23)
L362: interface Offset {
  // @since 4.1.0(11) | @stagemodelonly | @syscap SystemCapability.Collaboration.SystemShare
L370: x: number;
  // @since 4.1.0(11) | @stagemodelonly | @syscap SystemCapability.Collaboration.SystemShare
L378: y: number;
  // @since 4.1.0(11) | @stagemodelonly | @syscap SystemCapability.Collaboration.SystemShare
L387: interface Size {
  // @since 4.1.0(11) | @stagemodelonly | @syscap SystemCapability.Collaboration.SystemShare
L395: width: number;
  // @since 4.1.0(11) | @stagemodelonly | @syscap SystemCapability.Collaboration.SystemShare
L403: height: number;
  // @since 4.1.0(11) | @stagemodelonly | @syscap SystemCapability.Collaboration.SystemShare
L416: interface ShareControllerAnchor {
  // @since 4.1.0(11) | @stagemodelonly | @syscap SystemCapability.Collaboration.SystemShare
L424: windowOffset: Offset;
  // @since 4.1.0(11) | @stagemodelonly | @syscap SystemCapability.Collaboration.SystemShare
L442: enum SharePreviewMode {
  // @since 5.0.0(12) | @stagemodelonly | @syscap SystemCapability.Collaboration.SystemShare | @since 4.1.0(11)
L467: enum ShareAbilityType {
  // @since 4.1.0(11) | @stagemodelonly | @syscap SystemCapability.Collaboration.SystemShare | @since 5.0.0(12)
L516: enum SelectionMode {
  // @since 4.1.0(11) | @stagemodelonly | @syscap SystemCapability.Collaboration.SystemShare
L543: interface ShareControllerOptions {
  // @since 5.1.0(18) | @stagemodelonly | @syscap SystemCapability.Collaboration.SystemShare | @since 6.0.1(21) | @permission ohos.permission.SET_SYSTEMSHARE_APPLAUNCHTRUSTLIST | @since 5.0.0(12) | @since 4.1.0(11)
L602: enum ShareAbilityName {
  // @since 5.1.0(18) | @stagemodelonly | @syscap SystemCapability.Collaboration.SystemShare
L675: interface ShareAbilityInfo {
  // @since 5.1.0(18) | @stagemodelonly | @syscap SystemCapability.Collaboration.SystemShare
L687: name: string;
  // @since 5.1.0(18) | @stagemodelonly | @syscap SystemCapability.Collaboration.SystemShare
L696: interface ShareOperationResult {
  // @since 5.1.0(18) | @stagemodelonly | @syscap SystemCapability.Collaboration.SystemShare
L704: targetAbilityInfo: ShareAbilityInfo;
  // @since 4.1.0(11) | @stagemodelonly | @syscap SystemCapability.Collaboration.SystemShare | @since 5.1.0(18)
L719: class ShareController {
  // @since 4.1.0(11) | @stagemodelonly | @syscap SystemCapability.Collaboration.SystemShare
L729: constructor(data: SharedData);
  // @since 4.1.0(11) | @stagemodelonly | @syscap SystemCapability.Collaboration.SystemShare
L744: show(context: common.UIAbilityContext, options: ShareControllerOptions): Promise<void>;
  // @since 5.1.0(18) | @stagemodelonly | @syscap SystemCapability.Collaboration.SystemShare | @since 4.1.0(11)
L757: on(type: 'shareCompleted', callback: Callback<ShareOperationResult>): void;
  // @since 5.1.0(18) | @stagemodelonly | @syscap SystemCapability.Collaboration.SystemShare | @since 4.1.0(11)
L771: off(type: 'shareCompleted', callback?: Callback<ShareOperationResult>): void;
  // @since 4.1.0(11) | @stagemodelonly | @syscap SystemCapability.Collaboration.SystemShare | @since 5.1.0(18)
L783: on(event: 'dismiss', callback: () => void): void;
  // @since 4.1.0(11) | @stagemodelonly | @syscap SystemCapability.Collaboration.SystemShare | @since 5.1.0(18)
L796: off(event: 'dismiss', callback: () => void): void;
  // @since 5.0.0(12) | @stagemodelonly | @syscap SystemCapability.Collaboration.SystemShare | @since 4.1.0(11) | @since 5.1.0(18)
L805: enum ShareAbilityResultCode {
  // @since 4.1.0(11) | @stagemodelonly | @syscap SystemCapability.Collaboration.SystemShare | @since 5.0.0(12)
L839: interface ContactInfo {
  // @since 4.1.0(11) | @stagemodelonly | @syscap SystemCapability.Collaboration.SystemShare
L848: contactType: string;
  // @since 4.1.0(11) | @stagemodelonly | @syscap SystemCapability.Collaboration.SystemShare
L856: contactId: string;
  // @since 4.1.0(11) | @stagemodelonly | @syscap SystemCapability.Collaboration.SystemShare
L870: function getSharedData(want: Want): Promise<SharedData>;
  // @since 5.0.0(12) | @stagemodelonly | @syscap SystemCapability.Collaboration.SystemShare
L886: function getWant(data: SharedData, options?: ShareControllerOptions): Promise<Want>;
  // @since 4.1.0(11) | @stagemodelonly | @syscap SystemCapability.Collaboration.SystemShare
L899: function getContactInfo(want: Want): Promise<ContactInfo>;
```

### `hms/ets/api/@hms.core.deviceCloudGateway.cloudFunction.d.ts`

用途：云函数
大小：7 KB（含类/接口成员）

```ts
  // @since 5.0.0(12) | @atomicservice | @stagemodelonly | @syscap SystemCapability.DeviceCloudGateway.CloudFoundation
L17: declare namespace cloudFunction {
  // @since 5.0.0(12) | @atomicservice | @stagemodelonly | @syscap SystemCapability.DeviceCloudGateway.CloudFoundation | @permission ohos.permission.INTERNET
L35: function call(parameters: FunctionParams): Promise<FunctionResult>;
  // @since 5.0.0(12) | @atomicservice | @stagemodelonly | @syscap SystemCapability.DeviceCloudGateway.CloudFoundation | @permission ohos.permission.INTERNET
L55: function call(parameters: FunctionParams, callback: AsyncCallback<FunctionResult>): void;
  // @since 5.0.0(12) | @atomicservice | @stagemodelonly | @syscap SystemCapability.DeviceCloudGateway.CloudFoundation
L64: interface FunctionParams {
  // @since 5.0.0(12) | @atomicservice | @stagemodelonly | @syscap SystemCapability.DeviceCloudGateway.CloudFoundation
L75: name: string;
  // @since 5.0.0(12) | @atomicservice | @stagemodelonly | @syscap SystemCapability.DeviceCloudGateway.CloudFoundation | @since 6.0.1(21)
L144: enum LoadMode {
  // @since 5.0.0(12) | @atomicservice | @stagemodelonly | @syscap SystemCapability.DeviceCloudGateway.CloudFoundation
L183: interface FunctionResult {
  // @since 5.0.0(12) | @atomicservice | @stagemodelonly | @syscap SystemCapability.DeviceCloudGateway.CloudFoundation
L192: result: string | Object;
```

### `hms/ets/api/@hms.core.deviceCloudGateway.cloudDatabase.d.ts`

用途：云数据库
大小：29 KB（含类/接口成员）

```ts
  // @since 5.0.0(12) | @atomicservice | @stagemodelonly | @syscap SystemCapability.DeviceCloudGateway.CloudFoundation
L17: declare namespace cloudDatabase {
  // @since 5.0.0(12) | @atomicservice | @stagemodelonly | @syscap SystemCapability.DeviceCloudGateway.CloudFoundation
L28: function zone(zone: string): DatabaseZone;
  // @since 5.0.0(12) | @atomicservice | @stagemodelonly | @syscap SystemCapability.DeviceCloudGateway.CloudFoundation
L37: class DatabaseZone {
  // @since 5.0.0(12) | @atomicservice | @stagemodelonly | @syscap SystemCapability.DeviceCloudGateway.CloudFoundation | @permission ohos.permission.INTERNET
L56: query<T extends DatabaseObject>(condition: DatabaseQuery<T>): Promise<T[]>;
  // @since 5.0.0(12) | @atomicservice | @stagemodelonly | @syscap SystemCapability.DeviceCloudGateway.CloudFoundation | @permission ohos.permission.INTERNET
L76: query<T extends DatabaseObject>(condition: DatabaseQuery<T>, callback: AsyncCallback<T[]>): void;
  // @since 5.0.0(12) | @atomicservice | @stagemodelonly | @syscap SystemCapability.DeviceCloudGateway.CloudFoundation | @permission ohos.permission.INTERNET
L99: calculateQuery<T extends DatabaseObject>(condition: DatabaseQuery<T>, fieldName: string, calculate: QueryCalculate): Promise<number>;
  // @since 5.0.0(12) | @atomicservice | @stagemodelonly | @syscap SystemCapability.DeviceCloudGateway.CloudFoundation | @permission ohos.permission.INTERNET
L123: calculateQuery<T extends DatabaseObject>(condition: DatabaseQuery<T>, fieldName: string, calculate: QueryCalculate, callback: AsyncCallback<number>): void;
  // @since 5.0.0(12) | @atomicservice | @stagemodelonly | @syscap SystemCapability.DeviceCloudGateway.CloudFoundation | @permission ohos.permission.INTERNET
L142: upsert<T extends DatabaseObject>(objectList: T[] | T): Promise<number>;
  // @since 5.0.0(12) | @atomicservice | @stagemodelonly | @syscap SystemCapability.DeviceCloudGateway.CloudFoundation | @permission ohos.permission.INTERNET
L162: upsert<T extends DatabaseObject>(objectList: T[] | T, callback: AsyncCallback<number>): void;
  // @since 5.0.0(12) | @atomicservice | @stagemodelonly | @syscap SystemCapability.DeviceCloudGateway.CloudFoundation | @permission ohos.permission.INTERNET
L181: delete<T extends DatabaseObject>(objectList: T[] | T): Promise<number>;
  // @since 5.0.0(12) | @atomicservice | @stagemodelonly | @syscap SystemCapability.DeviceCloudGateway.CloudFoundation | @permission ohos.permission.INTERNET
L201: delete<T extends DatabaseObject>(objectList: T[] | T, callback: AsyncCallback<number>): void;
  // @since 5.0.0(12) | @atomicservice | @stagemodelonly | @syscap SystemCapability.DeviceCloudGateway.CloudFoundation | @permission ohos.permission.INTERNET
L211: class DatabaseObject {
  // @since 5.0.0(12) | @atomicservice | @stagemodelonly | @syscap SystemCapability.DeviceCloudGateway.CloudFoundation
L222: naturalbase_ClassName(): string;
  // @since 5.0.0(12) | @atomicservice | @stagemodelonly | @syscap SystemCapability.DeviceCloudGateway.CloudFoundation
L238: type FieldType = string | number | boolean | Uint8Array | Date;
  // @since 5.0.0(12) | @atomicservice | @stagemodelonly | @syscap SystemCapability.DeviceCloudGateway.CloudFoundation
L247: enum QueryCalculate {
  // @since 5.0.0(12) | @atomicservice | @stagemodelonly | @syscap SystemCapability.DeviceCloudGateway.CloudFoundation
L303: class DatabaseQuery<T extends DatabaseObject> {
  // @since 5.0.0(12) | @atomicservice | @stagemodelonly | @syscap SystemCapability.DeviceCloudGateway.CloudFoundation
L313: constructor(entityClass: new () => T);
  // @since 5.0.0(12) | @atomicservice | @stagemodelonly | @syscap SystemCapability.DeviceCloudGateway.CloudFoundation
L325: equalTo(fieldName: string, value: FieldType): DatabaseQuery<T>;
  // @since 5.0.0(12) | @atomicservice | @stagemodelonly | @syscap SystemCapability.DeviceCloudGateway.CloudFoundation
L337: notEqualTo(fieldName: string, value: FieldType): DatabaseQuery<T>;
  // @since 5.0.0(12) | @atomicservice | @stagemodelonly | @syscap SystemCapability.DeviceCloudGateway.CloudFoundation
L350: beginsWith(fieldName: string, value: FieldType): DatabaseQuery<T>;
  // @since 5.0.0(12) | @atomicservice | @stagemodelonly | @syscap SystemCapability.DeviceCloudGateway.CloudFoundation
L362: endsWith(fieldName: string, value: FieldType): DatabaseQuery<T>;
  // @since 5.0.0(12) | @atomicservice | @stagemodelonly | @syscap SystemCapability.DeviceCloudGateway.CloudFoundation
L375: contains(fieldName: string, value: FieldType): DatabaseQuery<T>;
  // @since 5.0.0(12) | @atomicservice | @stagemodelonly | @syscap SystemCapability.DeviceCloudGateway.CloudFoundation
L387: greaterThan(fieldName: string, value: FieldType): DatabaseQuery<T>;
  // @since 5.0.0(12) | @atomicservice | @stagemodelonly | @syscap SystemCapability.DeviceCloudGateway.CloudFoundation
L400: greaterThanOrEqualTo(fieldName: string, value: FieldType): DatabaseQuery<T>;
  // @since 5.0.0(12) | @atomicservice | @stagemodelonly | @syscap SystemCapability.DeviceCloudGateway.CloudFoundation
L412: lessThan(fieldName: string, value: FieldType): DatabaseQuery<T>;
  // @since 5.0.0(12) | @atomicservice | @stagemodelonly | @syscap SystemCapability.DeviceCloudGateway.CloudFoundation
L424: lessThanOrEqualTo(fieldName: string, value: FieldType): DatabaseQuery<T>;
  // @since 5.0.0(12) | @atomicservice | @stagemodelonly | @syscap SystemCapability.DeviceCloudGateway.CloudFoundation
L436: in(fieldName: string, values: FieldType[]): DatabaseQuery<T>;
  // @since 5.0.0(12) | @atomicservice | @stagemodelonly | @syscap SystemCapability.DeviceCloudGateway.CloudFoundation
L447: isNull(fieldName: string): DatabaseQuery<T>;
  // @since 5.0.0(12) | @atomicservice | @stagemodelonly | @syscap SystemCapability.DeviceCloudGateway.CloudFoundation
L458: isNotNull(fieldName: string): DatabaseQuery<T>;
  // @since 5.0.0(12) | @atomicservice | @stagemodelonly | @syscap SystemCapability.DeviceCloudGateway.CloudFoundation
L469: orderByAsc(fieldName: string): DatabaseQuery<T>;
  // @since 5.0.0(12) | @atomicservice | @stagemodelonly | @syscap SystemCapability.DeviceCloudGateway.CloudFoundation
L480: orderByDesc(fieldName: string): DatabaseQuery<T>;
  // @since 6.0.1(21) | @atomicservice | @stagemodelonly | @syscap SystemCapability.DeviceCloudGateway.CloudFoundation | @since 5.0.0(12)
L496: orderByRandom(): DatabaseQuery<T>;
  // @since 5.0.0(12) | @atomicservice | @stagemodelonly | @syscap SystemCapability.DeviceCloudGateway.CloudFoundation | @since 6.0.1(21)
L509: limit(count: number, offset?: number): DatabaseQuery<T>;
  // @since 5.0.0(12) | @atomicservice | @stagemodelonly | @syscap SystemCapability.DeviceCloudGateway.CloudFoundation | @since 6.0.1(21)
L533: beginGroup(): DatabaseQuery<T>;
  // @since 5.0.0(12) | @atomicservice | @stagemodelonly | @syscap SystemCapability.DeviceCloudGateway.CloudFoundation | @since 6.0.1(21)
L556: endGroup(): DatabaseQuery<T>;
  // @since 5.0.0(12) | @atomicservice | @stagemodelonly | @syscap SystemCapability.DeviceCloudGateway.CloudFoundation
L584: or(): DatabaseQuery<T>;
  // @since 5.0.0(12) | @atomicservice | @stagemodelonly | @syscap SystemCapability.DeviceCloudGateway.CloudFoundation
L612: and(): DatabaseQuery<T>;
```

### `hms/ets/api/@hms.core.deviceCloudGateway.cloudStorage.d.ts`

用途：云存储
大小：28 KB（含类/接口成员）

```ts
  // @since 5.0.0(12) | @atomicservice | @stagemodelonly | @syscap SystemCapability.DeviceCloudGateway.CloudFoundation
L20: declare namespace cloudStorage {
  // @since 5.0.0(12) | @atomicservice | @stagemodelonly | @syscap SystemCapability.DeviceCloudGateway.CloudFoundation
L37: function bucket(name?: string): StorageBucket;
  // @since 5.0.0(12) | @atomicservice | @stagemodelonly | @syscap SystemCapability.DeviceCloudGateway.CloudFoundation
L47: class StorageBucket {
  // @since 5.0.0(12) | @atomicservice | @stagemodelonly | @syscap SystemCapability.DeviceCloudGateway.CloudFoundation | @permission ohos.permission.INTERNET
L65: uploadFile(context: common.BaseContext, parameters: UploadParams): Promise<request.agent.Task>;
  // @since 5.0.0(12) | @atomicservice | @stagemodelonly | @syscap SystemCapability.DeviceCloudGateway.CloudFoundation | @permission ohos.permission.INTERNET
L85: uploadFile(context: common.BaseContext, parameters: UploadParams, callback: AsyncCallback<request.agent.Task>): void;
  // @since 5.0.0(12) | @atomicservice | @stagemodelonly | @syscap SystemCapability.DeviceCloudGateway.CloudFoundation | @permission ohos.permission.INTERNET
L103: downloadFile(context: common.BaseContext, parameters: DownloadParams): Promise<request.agent.Task>;
  // @since 5.0.0(12) | @atomicservice | @stagemodelonly | @syscap SystemCapability.DeviceCloudGateway.CloudFoundation | @permission ohos.permission.INTERNET
L123: downloadFile(context: common.BaseContext, parameters: DownloadParams, callback: AsyncCallback<request.agent.Task>): void;
  // @since 5.0.0(12) | @atomicservice | @stagemodelonly | @syscap SystemCapability.DeviceCloudGateway.CloudFoundation | @permission ohos.permission.INTERNET
L141: getDownloadURL(cloudPath: string): Promise<string>;
  // @since 5.0.0(12) | @atomicservice | @stagemodelonly | @syscap SystemCapability.DeviceCloudGateway.CloudFoundation | @permission ohos.permission.INTERNET
L160: getDownloadURL(cloudPath: string, callback: AsyncCallback<string>): void;
  // @since 5.0.0(12) | @atomicservice | @stagemodelonly | @syscap SystemCapability.DeviceCloudGateway.CloudFoundation | @permission ohos.permission.INTERNET
L178: deleteFile(cloudPath: string): Promise<void>;
  // @since 5.0.0(12) | @atomicservice | @stagemodelonly | @syscap SystemCapability.DeviceCloudGateway.CloudFoundation | @permission ohos.permission.INTERNET
L197: deleteFile(cloudPath: string, callback: AsyncCallback<void>): void;
  // @since 5.0.0(12) | @atomicservice | @stagemodelonly | @syscap SystemCapability.DeviceCloudGateway.CloudFoundation | @permission ohos.permission.INTERNET
L217: list(cloudPath: string, options?: ListOptions): Promise<ListResults>;
  // @since 5.0.0(12) | @atomicservice | @stagemodelonly | @syscap SystemCapability.DeviceCloudGateway.CloudFoundation | @permission ohos.permission.INTERNET
L239: list(cloudPath: string, options: ListOptions, callback: AsyncCallback<ListResults>): void;
  // @since 5.0.0(12) | @atomicservice | @stagemodelonly | @syscap SystemCapability.DeviceCloudGateway.CloudFoundation | @permission ohos.permission.INTERNET
L257: getMetadata(cloudPath: string): Promise<Metadata>;
  // @since 5.0.0(12) | @atomicservice | @stagemodelonly | @syscap SystemCapability.DeviceCloudGateway.CloudFoundation | @permission ohos.permission.INTERNET
L277: getMetadata(cloudPath: string, callback: AsyncCallback<Metadata>): void;
  // @since 5.0.0(12) | @atomicservice | @stagemodelonly | @syscap SystemCapability.DeviceCloudGateway.CloudFoundation | @permission ohos.permission.INTERNET
L297: setMetadata(cloudPath: string, metadata: MetadataUpdatable): Promise<Metadata>;
  // @since 5.0.0(12) | @atomicservice | @stagemodelonly | @syscap SystemCapability.DeviceCloudGateway.CloudFoundation | @permission ohos.permission.INTERNET
L317: setMetadata(cloudPath: string, metadata: MetadataUpdatable, callback: AsyncCallback<Metadata>): void;
  // @since 5.0.0(12) | @atomicservice | @stagemodelonly | @syscap SystemCapability.DeviceCloudGateway.CloudFoundation | @permission ohos.permission.INTERNET
L327: interface UploadParams {
  // @since 5.0.0(12) | @atomicservice | @stagemodelonly | @syscap SystemCapability.DeviceCloudGateway.CloudFoundation
L336: localPath: string;
  // @since 5.0.0(12) | @atomicservice | @stagemodelonly | @syscap SystemCapability.DeviceCloudGateway.CloudFoundation
L345: cloudPath: string;
  // @since 5.0.0(12) | @atomicservice | @stagemodelonly | @syscap SystemCapability.DeviceCloudGateway.CloudFoundation
L395: interface DownloadParams {
  // @since 5.0.0(12) | @atomicservice | @stagemodelonly | @syscap SystemCapability.DeviceCloudGateway.CloudFoundation
L404: localPath: string;
  // @since 5.0.0(12) | @atomicservice | @stagemodelonly | @syscap SystemCapability.DeviceCloudGateway.CloudFoundation
L413: cloudPath: string;
  // @since 5.0.0(12) | @atomicservice | @stagemodelonly | @syscap SystemCapability.DeviceCloudGateway.CloudFoundation
L468: interface ListOptions {
  // @since 5.0.0(12) | @atomicservice | @stagemodelonly | @syscap SystemCapability.DeviceCloudGateway.CloudFoundation
L497: interface ListResults {
  // @since 5.0.0(12) | @atomicservice | @stagemodelonly | @syscap SystemCapability.DeviceCloudGateway.CloudFoundation
L506: directories: string[];
  // @since 5.0.0(12) | @atomicservice | @stagemodelonly | @syscap SystemCapability.DeviceCloudGateway.CloudFoundation
L515: files: string[];
  // @since 5.0.0(12) | @atomicservice | @stagemodelonly | @syscap SystemCapability.DeviceCloudGateway.CloudFoundation
L534: interface MetadataUpdatable {
  // @since 5.0.0(12) | @atomicservice | @stagemodelonly | @syscap SystemCapability.DeviceCloudGateway.CloudFoundation
L599: interface Metadata extends MetadataUpdatable {
  // @since 5.0.0(12) | @atomicservice | @stagemodelonly | @syscap SystemCapability.DeviceCloudGateway.CloudFoundation
L608: name: string;
  // @since 5.0.0(12) | @atomicservice | @stagemodelonly | @syscap SystemCapability.DeviceCloudGateway.CloudFoundation
L617: size: number;
  // @since 5.0.0(12) | @atomicservice | @stagemodelonly | @syscap SystemCapability.DeviceCloudGateway.CloudFoundation
L626: createTime: Date;
  // @since 5.0.0(12) | @atomicservice | @stagemodelonly | @syscap SystemCapability.DeviceCloudGateway.CloudFoundation
L635: modifyTime: Date;
```

### `hms/ets/api/@hms.core.deviceCloudGateway.cloudCommon.d.ts`

用途：云开发公共类型
大小：9 KB（含类/接口成员）

```ts
  // @since 5.0.0(12) | @atomicservice | @stagemodelonly | @syscap SystemCapability.DeviceCloudGateway.CloudFoundation
L17: declare namespace cloudCommon {
  // @since 5.0.0(12) | @atomicservice | @stagemodelonly | @syscap SystemCapability.DeviceCloudGateway.CloudFoundation
L29: function init(options?: CloudOptions): void;
  // @since 5.0.0(12) | @atomicservice | @stagemodelonly | @syscap SystemCapability.DeviceCloudGateway.CloudFoundation
L38: interface CloudOptions {
  // @since 5.0.0(12) | @atomicservice | @stagemodelonly | @syscap SystemCapability.DeviceCloudGateway.CloudFoundation
L97: interface AuthProvider {
  // @since 5.0.0(12) | @atomicservice | @stagemodelonly | @syscap SystemCapability.DeviceCloudGateway.CloudFoundation
L111: getAccessToken(isForceRefresh: boolean): Promise<string>;
  // @since 5.0.0(12) | @atomicservice | @stagemodelonly | @syscap SystemCapability.DeviceCloudGateway.CloudFoundation
L121: enum CloudRegion {
  // @since 5.0.0(12) | @atomicservice | @stagemodelonly | @syscap SystemCapability.DeviceCloudGateway.CloudFoundation
L167: interface FunctionOptions {
  // @since 5.0.0(12) | @atomicservice | @stagemodelonly | @syscap SystemCapability.DeviceCloudGateway.CloudFoundation
L188: interface StorageOptions {
  // @since 5.0.0(12) | @atomicservice | @stagemodelonly | @syscap SystemCapability.DeviceCloudGateway.CloudFoundation
L227: interface DatabaseOptions {
```

### `hms/ets/api/@hms.core.deviceCloudGateway.cloudResPrefetch.d.ts`

用途：预加载
大小：7 KB（含类/接口成员）

```ts
  // @since 5.0.3(15) | @atomicservice | @stagemodelonly | @syscap SystemCapability.DeviceCloudGateway.CloudResPrefetch
L17: declare namespace cloudResPrefetch {
  // @since 5.0.3(15) | @atomicservice | @stagemodelonly | @syscap SystemCapability.DeviceCloudGateway.CloudResPrefetch
L34: function registerPrefetchTask(options: PrefetchOptions): void;
  // @since 5.0.3(15) | @atomicservice | @stagemodelonly | @syscap SystemCapability.DeviceCloudGateway.CloudResPrefetch
L53: function getPrefetchResult(mode: PrefetchMode, params?: PrefetchParams): Promise<PrefetchResult>;
  // @since 5.0.3(15) | @atomicservice | @stagemodelonly | @syscap SystemCapability.DeviceCloudGateway.CloudResPrefetch
L74: function getPrefetchResult(mode: PrefetchMode, callback: AsyncCallback<PrefetchResult>, params?: PrefetchParams): void;
  // @since 5.0.3(15) | @atomicservice | @stagemodelonly | @syscap SystemCapability.DeviceCloudGateway.CloudResPrefetch
L83: interface PrefetchOptions {
  // @since 5.0.3(15) | @atomicservice | @stagemodelonly | @syscap SystemCapability.DeviceCloudGateway.CloudResPrefetch
L112: enum PrefetchMode {
  // @since 6.1.0(23) | @stagemodelonly | @syscap SystemCapability.DeviceCloudGateway.CloudResPrefetch | @since 5.0.3(15) | @atomicservice
L151: interface PrefetchParams {
  // @since 5.0.3(15) | @atomicservice | @stagemodelonly | @syscap SystemCapability.DeviceCloudGateway.CloudResPrefetch | @since 6.1.0(23)
L171: interface PrefetchResult {
  // @since 5.0.3(15) | @atomicservice | @stagemodelonly | @syscap SystemCapability.DeviceCloudGateway.CloudResPrefetch
L180: result: string | Object;
  // @since 5.0.3(15) | @atomicservice | @stagemodelonly | @syscap SystemCapability.DeviceCloudGateway.CloudResPrefetch
L189: timestamp: Date;
  // @since 5.0.3(15) | @atomicservice | @stagemodelonly | @syscap SystemCapability.DeviceCloudGateway.CloudResPrefetch
L198: token: string;
```

### `openharmony/ets/api/@ohos.app.ability.UIExtensionAbility.d.ts`

用途：UIExtensionAbility onDestroy 异步警告
大小：6 KB（含类/接口成员）

```ts
  // @since 10 | @stagemodelonly | @syscap SystemCapability.Ability.AbilityRuntime.Core
L44: declare class UIExtensionAbility extends ExtensionAbility {
  // @since 10 | @stagemodelonly | @syscap SystemCapability.Ability.AbilityRuntime.AbilityCore
L52: context: UIExtensionContext;
  // @since 10 | @stagemodelonly | @syscap SystemCapability.Ability.AbilityRuntime.Core | @syscap SystemCapability.Ability.AbilityRuntime.AbilityCore
L63: onCreate(launchParam: AbilityConstant.LaunchParam): void;
  // @since 10 | @stagemodelonly | @syscap SystemCapability.Ability.AbilityRuntime.Core | @syscap SystemCapability.Ability.AbilityRuntime.AbilityCore
L74: onSessionCreate(want: Want, session: UIExtensionContentSession): void;
  // @since 10 | @stagemodelonly | @syscap SystemCapability.Ability.AbilityRuntime.Core | @syscap SystemCapability.Ability.AbilityRuntime.AbilityCore
L84: onSessionDestroy(session: UIExtensionContentSession): void;
  // @since 10 | @stagemodelonly | @syscap SystemCapability.Ability.AbilityRuntime.AbilityCore | @syscap SystemCapability.Ability.AbilityRuntime.Core
L93: onForeground(): void;
  // @since 10 | @stagemodelonly | @syscap SystemCapability.Ability.AbilityRuntime.AbilityCore | @syscap SystemCapability.Ability.AbilityRuntime.Core
L102: onBackground(): void;
  // @since 10 | @stagemodelonly | @syscap SystemCapability.Ability.AbilityRuntime.Core | @syscap SystemCapability.Ability.AbilityRuntime.AbilityCore
L115: onDestroy(): void | Promise<void>;
```

### `openharmony/ets/api/@ohos.app.ability.ShareExtensionAbility.d.ts`

用途：分享详情页扩展能力
大小：2 KB（含类/接口成员）

```ts
```

### `openharmony/ets/api/@ohos.app.ability.UIAbility.d.ts`

用途：UIAbility 生命周期与 onNewWant
大小：39 KB（含类/接口成员）

```ts
  // @since 9 | @stagemodelonly | @syscap SystemCapability.Ability.AbilityRuntime.AbilityCore
L80: export interface OnReleaseCallback {
  // @since 10 | @stagemodelonly | @syscap SystemCapability.Ability.AbilityRuntime.AbilityCore | @since 9
L98: export interface OnRemoteStateChangeCallback {
  // @since 9 | @stagemodelonly | @syscap SystemCapability.Ability.AbilityRuntime.AbilityCore | @since 10
L116: export interface CalleeCallback {
  // @since 9 | @stagemodelonly | @syscap SystemCapability.Ability.AbilityRuntime.AbilityCore
L138: export interface Caller {
  // @since 9 | @stagemodelonly | @syscap SystemCapability.Ability.AbilityRuntime.AbilityCore
L157: call(method: string, data: rpc.Parcelable): Promise<void>;
  // @since 9 | @stagemodelonly | @syscap SystemCapability.Ability.AbilityRuntime.AbilityCore
L176: callWithResult(method: string, data: rpc.Parcelable): Promise<rpc.MessageSequence>;
  // @since 9 | @stagemodelonly | @syscap SystemCapability.Ability.AbilityRuntime.AbilityCore
L188: release(): void;
  // @since 9 | @stagemodelonly | @syscap SystemCapability.Ability.AbilityRuntime.AbilityCore
L200: onRelease(callback: OnReleaseCallback): void;
  // @since 10 | @stagemodelonly | @syscap SystemCapability.Ability.AbilityRuntime.AbilityCore | @since 9
L213: onRemoteStateChange(callback: OnRemoteStateChangeCallback): void;
  // @since 9 | @stagemodelonly | @syscap SystemCapability.Ability.AbilityRuntime.AbilityCore | @since 10
L226: on(type: 'release', callback: OnReleaseCallback): void;
  // @since 9 | @stagemodelonly | @syscap SystemCapability.Ability.AbilityRuntime.AbilityCore | @since 10
L239: off(type: 'release', callback: OnReleaseCallback): void;
  // @since 9 | @stagemodelonly | @syscap SystemCapability.Ability.AbilityRuntime.AbilityCore | @since 10
L251: off(type: 'release'): void;
  // @since 9 | @stagemodelonly | @syscap SystemCapability.Ability.AbilityRuntime.AbilityCore | @since 10
L261: export interface Callee {
  // @since 9 | @stagemodelonly | @syscap SystemCapability.Ability.AbilityRuntime.AbilityCore
L278: on(method: string, callback: CalleeCallback): void;
  // @since 9 | @stagemodelonly | @syscap SystemCapability.Ability.AbilityRuntime.AbilityCore
L291: off(method: string): void;
  // @since 9 | @atomicservice [since 11] | @stagemodelonly | @syscap SystemCapability.Ability.AbilityRuntime.AbilityCore
L303: declare class UIAbility extends Ability {
  // @since 9 | @atomicservice [since 11] | @stagemodelonly | @syscap SystemCapability.Ability.AbilityRuntime.AbilityCore
L313: context: UIAbilityContext;
  // @since 9 | @atomicservice [since 11] | @stagemodelonly | @syscap SystemCapability.Ability.AbilityRuntime.AbilityCore
L324: launchWant: Want;
  // @since 9 | @atomicservice [since 11] | @stagemodelonly | @syscap SystemCapability.Ability.AbilityRuntime.AbilityCore
L336: lastRequestWant: Want;
  // @since 9 | @stagemodelonly | @syscap SystemCapability.Ability.AbilityRuntime.AbilityCore | @atomicservice [since 11]
L345: callee: Callee;
  // @since 9 | @atomicservice [since 11] | @stagemodelonly | @syscap SystemCapability.Ability.AbilityRuntime.AbilityCore | @since 23
L372: onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void;
  // @since 9 | @atomicservice [since 11] | @stagemodelonly | @syscap SystemCapability.Ability.AbilityRuntime.AbilityCore | @since 23
L384: onWindowStageCreate(windowStage: window.WindowStage): void;
  // @since 12 | @atomicservice | @stagemodelonly | @syscap SystemCapability.Ability.AbilityRuntime.AbilityCore | @since 9 | @atomicservice [since 11] | @since 23
L395: onWindowStageWillDestroy(windowStage: window.WindowStage): void;
  // @since 9 | @atomicservice [since 11] | @stagemodelonly | @syscap SystemCapability.Ability.AbilityRuntime.AbilityCore | @since 12 | @atomicservice | @since 23
L409: onWindowStageDestroy(): void;
  // @since 9 | @atomicservice [since 11] | @stagemodelonly | @syscap SystemCapability.Ability.AbilityRuntime.AbilityCore | @since 12 | @atomicservice
L427: onWindowStageRestore(windowStage: window.WindowStage): void;
  // @since 9 | @atomicservice [since 11] | @stagemodelonly | @syscap SystemCapability.Ability.AbilityRuntime.AbilityCore | @since 12 | @atomicservice
L451: onDestroy(): void | Promise<void>;
  // @since 9 | @atomicservice [since 11] | @stagemodelonly | @syscap SystemCapability.Ability.AbilityRuntime.AbilityCore
L465: onForeground(): void;
  // @since 20 | @atomicservice | @stagemodelonly | @syscap SystemCapability.Ability.AbilityRuntime.AbilityCore | @since 9 | @atomicservice [since 11]
L480: onWillForeground(): void;
  // @since 20 | @atomicservice | @stagemodelonly | @syscap SystemCapability.Ability.AbilityRuntime.AbilityCore | @since 9 | @atomicservice [since 11]
L495: onDidForeground(): void;
  // @since 9 | @atomicservice [since 11] | @stagemodelonly | @syscap SystemCapability.Ability.AbilityRuntime.AbilityCore | @since 20 | @atomicservice
L508: onBackground(): void;
  // @since 20 | @atomicservice | @stagemodelonly | @syscap SystemCapability.Ability.AbilityRuntime.AbilityCore | @since 9 | @atomicservice [since 11]
L521: onWillBackground(): void;
  // @since 20 | @atomicservice | @stagemodelonly | @syscap SystemCapability.Ability.AbilityRuntime.AbilityCore | @since 9 | @atomicservice [since 11]
L534: onDidBackground(): void;
  // @since 9 | @atomicservice [since 11] | @stagemodelonly | @syscap SystemCapability.Ability.AbilityRuntime.AbilityCore | @since 20 | @atomicservice
L561: onContinue(wantParam: Record<string, Object>): AbilityConstant.OnContinueResult | Promise<AbilityConstant.OnContinueResult>;
  // @since 9 | @atomicservice [since 11] | @stagemodelonly | @syscap SystemCapability.Ability.AbilityRuntime.AbilityCore | @since 20 | @atomicservice
L578: onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void;
  // @since 9 | @atomicservice [since 11] | @stagemodelonly | @syscap SystemCapability.Ability.AbilityRuntime.AbilityCore | @since 20 | @atomicservice
L590: onDump(params: Array<string>): Array<string>;
  // @since 9 | @atomicservice [since 11] | @stagemodelonly | @syscap SystemCapability.Ability.AbilityRuntime.AbilityCore
L616: onSaveState(reason: AbilityConstant.StateType, wantParam: Record<string, Object>): AbilityConstant.OnSaveResult;
  // @since 20 | @atomicservice | @stagemodelonly | @syscap SystemCapability.Ability.AbilityRuntime.AbilityCore | @since 9 | @atomicservice [since 11]
L635: onSaveStateAsync(stateType: AbilityConstant.StateType, wantParam: Record<string, Object>): Promise<AbilityConstant.OnSaveResult>;
  // @since 10 | @atomicservice [since 11] | @stagemodelonly | @syscap SystemCapability.Ability.AbilityRuntime.AbilityCore | @since 20 | @atomicservice | @since 9
L647: onShare(wantParam: Record<string, Object>): void;
  // @since 10 | @atomicservice [since 11] | @stagemodelonly | @syscap SystemCapability.Ability.AbilityRuntime.AbilityCore | @permission ohos.permission.PREPARE_APP_TERMINATE | @since 20 | @atomicservice | @since 9
L681: onPrepareToTerminate(): boolean;
  // @since 15 | @atomicservice | @stagemodelonly | @syscap SystemCapability.Ability.AbilityRuntime.AbilityCore | @permission ohos.permission.PREPARE_APP_TERMINATE | @since 10 | @atomicservice [since 11]
L720: onPrepareToTerminateAsync(): Promise<boolean>;
  // @since 10 | @atomicservice [since 11] | @stagemodelonly | @syscap SystemCapability.Ability.AbilityRuntime.AbilityCore | @since 15 | @atomicservice | @permission ohos.permission.PREPARE_APP_TERMINATE
L737: onBackPressed(): boolean;
  // @since 18 | @stagemodelonly | @syscap SystemCapability.Ability.AbilityRuntime.AbilityCore | @since 10 | @atomicservice [since 11] | @since 15 | @atomicservice | @permission ohos.permission.PREPARE_APP_TERMINATE
L766: onCollaborate(wantParam: Record<string, Object>): AbilityConstant.CollaborateResult;
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.Ability.AbilityRuntime.AbilityCore | @since 18 | @since 10 | @atomicservice [since 11] | @since 15 | @atomicservice | @permission ohos.permission.PREPARE_APP_TERMINATE
L776: isDestroyed: boolean;
```

### `openharmony/ets/api/@ohos.app.ability.Want.d.ts`

用途：Want 与 wantConstant
大小：9 KB（含类/接口成员）

```ts
```

### `openharmony/ets/api/@ohos.app.ability.common.d.ts`

用途：Context 族
大小：13 KB（含类/接口成员）

```ts
  // @since 9 | @atomicservice [since 11] | @stagemodelonly | @syscap SystemCapability.Ability.AbilityRuntime.Core
L51: declare namespace common {
  // @since 9 | @atomicservice [since 11] | @stagemodelonly | @syscap SystemCapability.Ability.AbilityRuntime.Core
L61: export type UIAbilityContext = _UIAbilityContext.default;
  // @since 9 | @atomicservice [since 11] | @stagemodelonly | @syscap SystemCapability.Ability.AbilityRuntime.Core
L72: export type AbilityStageContext = _AbilityStageContext.default;
  // @since 9 | @atomicservice [since 11] | @stagemodelonly | @syscap SystemCapability.Ability.AbilityRuntime.Core
L82: export type ApplicationContext = _ApplicationContext.default;
  // @since 9 | @atomicservice [since 11] | @stagemodelonly | @syscap SystemCapability.Ability.AbilityRuntime.Core
L92: export type BaseContext = _BaseContext.default;
  // @since 9 | @atomicservice [since 11] | @stagemodelonly | @syscap SystemCapability.Ability.AbilityRuntime.Core
L103: export type Context = _Context.default;
  // @since 9 | @atomicservice [since 11] | @stagemodelonly | @syscap SystemCapability.Ability.AbilityRuntime.Core
L113: export type ExtensionContext = _ExtensionContext.default;
  // @since 11 | @atomicservice | @stagemodelonly | @syscap SystemCapability.Ability.AbilityRuntime.Core | @since 9
L132: export type FormExtensionContext = _FormExtensionContext.default;
  // @since 22 | @atomicservice | @stagemodelonly | @syscap SystemCapability.Ability.Form
L143: export type FormEditExtensionContext = _FormEditExtensionContext.default;
  // @since 22 | @atomicservice | @stagemodelonly | @syscap SystemCapability.Ability.Form
L154: export type LiveFormExtensionContext = _LiveFormExtensionContext.default;
  // @since 9 | @atomicservice [since 11] | @stagemodelonly | @syscap SystemCapability.Ability.AbilityRuntime.Core
L164: export type EventHub = _EventHub.default;
  // @since 9 | @atomicservice [since 11] | @syscap SystemCapability.Ability.AbilityRuntime.Core
L172: export type PacMap = _PacMap;
  // @since 9 | @atomicservice [since 11] | @stagemodelonly | @syscap SystemCapability.Ability.AbilityRuntime.Core
L181: export type AbilityResult = _AbilityResult;
  // @since 9 | @stagemodelonly | @syscap SystemCapability.Ability.AbilityRuntime.Core
L190: export type ConnectOptions = _ConnectOptions;
  // @since 10 | @stagemodelonly | @syscap SystemCapability.Ability.AbilityRuntime.Core
L199: export type UIExtensionContext = _UIExtensionContext.default;
  // @since 11 | @atomicservice | @stagemodelonly | @syscap SystemCapability.Ability.AbilityRuntime.Core
L213: export type AbilityStartCallback = _AbilityStartCallback;
  // @since 11 | @stagemodelonly | @syscap SystemCapability.Ability.AbilityRuntime.Core
L224: export type VpnExtensionContext = _VpnExtensionContext.default;
  // @since 12 | @atomicservice | @stagemodelonly | @syscap SystemCapability.Ability.AbilityRuntime.Core
L234: export type EmbeddableUIAbilityContext = _EmbeddableUIAbilityContext.default;
  // @since 12 | @stagemodelonly | @syscap SystemCapability.Ability.AppExtension.PhotoEditorExtension
L243: export type PhotoEditorExtensionContext = _PhotoEditorExtensionContext.default;
  // @since 14 | @atomicservice | @stagemodelonly | @syscap SystemCapability.Ability.AbilityRuntime.Core
L254: export type UIServiceProxy = _UIServiceProxy.default;
  // @since 14 | @atomicservice | @stagemodelonly | @syscap SystemCapability.Ability.AbilityRuntime.Core
L264: export type UIServiceExtensionConnectCallback = _UIServiceExtensionConnectCallback.default;
  // @since 20 | @stagemodelonly | @syscap SystemCapability.Ability.AbilityRuntime.Core
L274: export type AppServiceExtensionContext = _AppServiceExtensionContext.default;
  // @since 24 | @atomicservice | @stagemodelonly | @syscap SystemCapability.Ability.AgentRuntime.Core
L283: export type AgentCard = _AgentCard;
  // @since 24 | @atomicservice | @stagemodelonly | @syscap SystemCapability.Ability.AgentRuntime.Core
L293: export type AgentProvider = _AgentProvider;
  // @since 24 | @atomicservice | @stagemodelonly | @syscap SystemCapability.Ability.AgentRuntime.Core
L303: export type AgentCapabilities = _AgentCapabilities;
  // @since 24 | @atomicservice | @stagemodelonly | @syscap SystemCapability.Ability.AgentRuntime.Core
L313: export type AgentSkill = _AgentSkill;
  // @since 24 | @atomicservice | @stagemodelonly | @syscap SystemCapability.Ability.AgentRuntime.Core
L322: export type AgentAppInfo = _AgentAppInfo;
  // @since 24 | @atomicservice | @stagemodelonly | @syscap SystemCapability.Ability.AgentRuntime.Core
L332: export type AgentHostProxy = _AgentHostProxy;
  // @since 24 | @atomicservice | @stagemodelonly | @syscap SystemCapability.Ability.AgentRuntime.Core
L342: export type AgentExtensionContext = _AgentExtensionContext;
```

### `openharmony/ets/api/@ohos.multimedia.image.d.ts`

用途：createImageSource 只支持沙箱路径
大小：548 KB（超过 200 KB，只出顶层声明、不摘 JSDoc 与类成员）

```ts
L114: declare namespace image {
L124: enum PixelMapFormat {
L316: interface Size {
L362: enum PropertyKey {
L2363: enum ImageFormat {
L2388: enum AlphaType {
L2436: enum DecodingDynamicRange {
L2470: enum PackingDynamicRange {
L2495: enum AntiAliasingLevel {
L2538: enum ScaleMode {
L2566: enum ComponentType {
L2602: enum HdrMetadataKey {
L2638: enum HdrMetadataType {
L2674: enum AllocatorType {
L2724: enum CropAndScaleStrategy {
L2751: interface Region {
L2792: interface PositionArea {
L2846: interface ImageInfo {
L2932: interface PackingOptionsForTiff {
L2987: interface PackingSizeLimit {
L3013: interface PackingOption {
L3131: interface PackingOptionsForSequence {
L3183: interface GetImagePropertyOptions {
L3212: interface ImagePropertyOptions {
L3239: interface DecodingOptions {
L3371: interface Component {
L3412: interface InitializationOptions {
L3481: interface SourceOptions {
L3527: interface HdrStaticMetadata {
L3608: interface GainmapChannel {
L3652: interface HdrGainmapMetadata {
L3710: interface ImageReceiverOptions {
L3737: interface ImageBufferData {
L3778: type HdrMetadataValue = HdrMetadataType | HdrStaticMetadata | ArrayBuffer | HdrGainmapMetadata;
L3809: function createPixelMapFromPixels(pixels: ArrayBuffer, param: InitializationOptions): Promise<PixelMap>;
L3840: function createPixelMapFromPixelsSync(pixels: ArrayBuffer, param: InitializationOptions): PixelMap;
L3862: function createPixelMap(colors: ArrayBuffer, options: InitializationOptions, callback: AsyncCallback<PixelMap>): void;
L3884: function createPixelMap(colors: ArrayBuffer, options: InitializationOptions): Promise<PixelMap>;
L3899: function createPixelMapSync(colors: ArrayBuffer, options: InitializationOptions): PixelMap;
L3916: function createPixelMapUsingAllocator(colors: ArrayBuffer, param: InitializationOptions, allocatorType?: AllocatorType): Promise<PixelMap>;
L3933: function createPixelMapUsingAllocatorSync(colors: ArrayBuffer, param: InitializationOptions, allocatorType?: AllocatorType): PixelMap;
L3954: function createEmptyPixelMap(param: InitializationOptions): PixelMap;
L3968: function createPixelMapSync(options: InitializationOptions): PixelMap;
L3983: function createPixelMapUsingAllocatorSync(param: InitializationOptions, allocatorType?: AllocatorType): PixelMap;
L4000: function createPremultipliedPixelMap(src: PixelMap, dst: PixelMap, callback: AsyncCallback<void>): void;
L4017: function createPremultipliedPixelMap(src: PixelMap, dst: PixelMap): Promise<void>;
L4034: function createUnpremultipliedPixelMap(src: PixelMap, dst: PixelMap, callback: AsyncCallback<void>): void;
L4051: function createUnpremultipliedPixelMap(src: PixelMap, dst: PixelMap): Promise<void>;
L4072: function createPixelMapFromParcel(sequence: rpc.MessageSequence): PixelMap;
L4085: function createPixelMapFromSurface(surfaceId: string, region: Region): Promise<PixelMap>;
L4099: function createPixelMapFromSurfaceSync(surfaceId: string, region: Region): PixelMap;
L4112: function createPixelMapFromSurface(surfaceId: string): Promise<PixelMap>;
L4125: function createPixelMapFromSurfaceSync(surfaceId: string): PixelMap;
L4144: function createPixelMapFromSurfaceWithTransformation(surfaceId: string, transformEnabled: boolean): Promise<PixelMap>;
L4163: function createPixelMapFromSurfaceWithTransformationSync(surfaceId: string, transformEnabled: boolean): PixelMap;
L4182: function createImageSource(uri: string): ImageSource;
L4204: function createImageSource(uri: string, options: SourceOptions): ImageSource;
L4220: function createImageSource(fd: number): ImageSource;
L4239: function createImageSource(fd: number, options: SourceOptions): ImageSource;
L4258: function createImageSource(buf: ArrayBuffer): ImageSource;
L4279: function createImageSource(buf: ArrayBuffer, options: SourceOptions): ImageSource;
L4296: function createImageSource(rawfile: resourceManager.RawFileDescriptor, options?: SourceOptions): ImageSource;
L4338: function CreateIncrementalSource(buf: ArrayBuffer): ImageSource;
L4359: function CreateIncrementalSource(buf: ArrayBuffer, options?: SourceOptions): ImageSource;
L4374: function createImagePacker(): ImagePacker;
L4402: function createImageReceiver(width: number, height: number, format: number, capacity: number): ImageReceiver;
L4428: function createImageReceiver(size: Size, format: ImageFormat, capacity: number): ImageReceiver;
L4440: function createImageReceiver(options?: ImageReceiverOptions): ImageReceiver | undefined;
L4458: function createImageCreator(width: number, height: number, format: number, capacity: number): ImageCreator;
L4475: function createImageCreator(size: Size, format: ImageFormat, capacity: number): ImageCreator;
L4502: interface PixelMap {
L6022: interface HdrComposeOptions {
L6047: interface Picture {
L6196: function createPicture(mainPixelmap: PixelMap): Picture;
L6215: function createPictureFromParcel(sequence: rpc.MessageSequence): Picture;
L6235: function createAuxiliaryPicture(buffer: ArrayBuffer, size: Size, type: AuxiliaryPictureType): AuxiliaryPicture;
L6254: function createAuxiliaryPictureUsingAllocator(auxiliaryPictureInfo: AuxiliaryPictureInfo, allocatorType?: AllocatorType, pixels?: ArrayBuffer): AuxiliaryPicture;
L6278: interface AuxiliaryPicture {
L6379: enum AuxiliaryPictureType {
L6452: enum MetadataType {
L6546: interface Metadata {
L6634: enum FragmentMapPropertyKey {
L6670: enum GifPropertyKey {
L6733: enum HeifsPropertyKey {
L6771: enum DngPropertyKey {
L7492: enum TiffPropertyKey {
L7661: enum JfifPropertyKey {
L7710: enum PngPropertyKey {
L7849: class HeifsMetadata implements Metadata {
L7969: class JfifMetadata {
L8020: class GifMetadata {
L8095: class TiffMetadata {
L8269: class PngMetadata {
L8399: enum Orientation {
L8474: class ExifMetadata implements Metadata {
L9746: const XMAGE_WATERMARK_MODE_AT_THE_BOTTOM: number;
L9754: const XMAGE_WATERMARK_MODE_BORDER: number;
L9762: const CAPTURE_MODE_PROFESSIONAL: number;
L9770: const CAPTURE_MODE_FRONT_LENS_NIGHT_VIEW: number;
L9778: const CAPTURE_MODE_PANORAMA: number;
L9786: const CAPTURE_MODE_TAIL_LIGHT: number;
L9794: const CAPTURE_MODE_LIGHT_GRAFFITI: number;
L9802: const CAPTURE_MODE_SILKY_WATER: number;
L9810: const CAPTURE_MODE_STAR_TRACK: number;
L9818: const CAPTURE_MODE_WIDEAPERTURE: number;
L9826: const CAPTURE_MODE_MOVING_PHOTO: number;
L9834: const CAPTURE_MODE_PORTRAIT: number;
L9842: const CAPTURE_MODE_REAR_LENS_NIGHT_VIEW: number;
L9850: const CAPTURE_MODE_SUPER_MACRO: number;
L9858: const CAPTURE_MODE_SNAP_SHOT: number;
L9866: enum FocusMode {
L9907: enum XmageColorMode {
L9950: class MakerNoteHuaweiMetadata implements Metadata {
L10312: class DngMetadata {
L11033: enum WebPPropertyKey {
L11082: class WebPMetadata {
L11135: enum XMPTagType {
L11200: interface XMPNamespace {
L11225: const XMP_BASIC: XMPNamespace;
L11233: const XMP_RIGHTS: XMPNamespace;
L11241: const EXIF: XMPNamespace;
L11249: const DUBLIN_CORE: XMPNamespace;
L11257: const TIFF: XMPNamespace;
L11265: interface XMPTag {
L11306: interface XMPEnumerateOptions {
L11332: class XMPMetadata {
L11446: enum AvisPropertyKey {
L11463: class AvisMetadata {
L11481: interface ImageMetadata {
L11575: interface DecodingOptionsForPicture {
L11612: interface DecodingOptionsForThumbnail {
L11642: interface AuxiliaryPictureInfo {
L11686: interface ImageRawData {
L11724: interface ImageSource {
L12751: interface BinaryBufferInfo {
L12800: interface ImagePacker {
L13186: interface Image {
L13351: interface ImageReceiver {
L13529: interface ImageCreator {
L13641: function getImageSourceSupportedFormats(): string[];
L13649: function getImagePackerSupportedFormats(): string[];
```

### `openharmony/ets/api/@ohos.multimedia.audio.d.ts`

用途：AudioCapturer 参数枚举
大小：370 KB（超过 200 KB，只出顶层声明、不摘 JSDoc 与类成员）

```ts
L36: declare namespace audio {
L44: enum AudioErrors {
L107: const DEFAULT_VOLUME_GROUP_ID: number;
L114: const DEFAULT_INTERRUPT_GROUP_ID: number;
L124: function getAudioManager(): AudioManager;
L139: function createAudioCapturer(options: AudioCapturerOptions, callback: AsyncCallback<AudioCapturer>): void;
L154: function createAudioCapturer(options: AudioCapturerOptions): Promise<AudioCapturer>;
L182: function createAudioRenderer(options: AudioRendererOptions, callback: AsyncCallback<AudioRenderer>): void;
L208: function createAudioRenderer(options: AudioRendererOptions): Promise<AudioRenderer>;
L234: function createAudioLoopback(mode: AudioLoopbackMode): Promise<AudioLoopback>;
L242: enum AudioState {
L306: enum AudioLoopbackMode {
L321: enum AudioLoopbackStatus {
L359: enum AudioLoopbackReverbPreset {
L395: enum AudioLoopbackEqualizerPreset {
L425: enum AudioVolumeType {
L481: enum DeviceFlag {
L513: enum DeviceUsage {
L565: enum DeviceRole {
L593: enum DeviceType {
L770: type DeviceTypeArray = Array<DeviceType>;
L779: enum ActiveDeviceType {
L812: enum CommunicationDeviceType {
L833: enum AudioRingMode {
L866: enum AudioSampleFormat {
L929: enum AudioChannel {
L1042: enum AudioSamplingRate {
L1169: enum AudioEncodingType {
L1197: enum ContentType {
L1261: enum StreamUsage {
L1414: interface AudioStreamInfo {
L1465: interface AudioRendererInfo {
L1510: interface AudioRendererOptions {
L1543: enum AudioPrivacyType {
L1583: enum InterruptMode {
L1609: enum AudioRendererRate {
L1640: enum InterruptType {
L1677: enum InterruptHint {
L1762: enum InterruptForceType {
L1790: interface InterruptEvent {
L1827: enum InterruptActionType {
L1854: enum DeviceChangeType {
L1879: enum AudioScene {
L1922: interface AudioManager {
L2490: enum DeviceBlockStatus {
L2512: interface DeviceBlockStatusInfo {
L2543: interface AudioRoutingManager {
L2981: interface AudioStreamManager {
L3363: enum AudioConcurrencyMode {
L3408: enum AudioSessionDeactivatedReason {
L3432: enum AudioSessionScene {
L3469: enum AudioSessionStateChangeHint {
L3577: enum OutputDeviceChangeRecommendedAction {
L3602: enum AudioSessionBehaviorFlags {
L3653: interface AudioSessionStrategy {
L3672: interface AudioSessionDeactivatedEvent {
L3688: interface AudioSessionStateChangedEvent {
L3703: interface CurrentOutputDeviceChangedEvent {
L3740: enum BluetoothAndNearlinkPreferredRecordCategory {
L3777: interface CurrentInputDeviceChangedEvent {
L3810: interface AudioSessionManager {
L4257: interface AudioVolumeManager {
L4470: interface AudioVolumeGroupManager {
L4905: interface AudioSpatializationManager {
L4952: interface SystemRecordControllerConfig {
L4973: interface AudioDeviceEnhanceManager {
L5086: interface AudioRecordingManager {
L5117: interface AudioDebuggingManager {
L5205: type AudioRendererChangeInfoArray = Array<Readonly<AudioRendererChangeInfo>>;
L5213: interface AudioRendererChangeInfo {
L5246: type AudioCapturerChangeInfoArray = Array<Readonly<AudioCapturerChangeInfo>>;
L5254: interface AudioCapturerChangeInfo {
L5296: interface AudioDeviceDescriptor {
L5424: type AudioDeviceDescriptors = Array<Readonly<AudioDeviceDescriptor>>;
L5431: enum AudioVolumeMode {
L5454: interface VolumeEvent {
L5491: interface StreamVolumeEvent {
L5530: interface InterruptAction {
L5578: interface AudioInterrupt {
L5614: interface MicStateChangeEvent {
L5630: interface DeviceChangeAction {
L5655: enum ChannelBlendMode {
L5697: enum AudioStreamDeviceChangeReason {
L5757: interface AudioStreamDeviceChangeInfo {
L5793: enum AudioDataCallbackResult {
L5825: type AudioRendererWriteDataCallback = (data: ArrayBuffer) => AudioDataCallbackResult | void;
L5832: interface AudioTimestampInfo {
L5855: enum AudioLatencyType {
L5896: interface AudioRenderer {
L6912: enum SourceType {
L6986: enum AudioPlaybackCaptureMode {
L7016: enum PlaybackCaptureStartState {
L7047: interface AudioCapturerInfo {
L7074: interface AudioCapturerOptions {
L7120: interface CaptureFilterOptions {
L7146: interface AudioPlaybackCaptureConfig {
L7172: interface AudioCapturer {
L7767: type AudioEffectInfoArray = Array<Readonly<AudioEffectMode>>;
L7775: enum AudioEffectMode {
L7801: enum AudioChannelLayout {
L8230: interface AudioDevicePair {
L8271: interface AudioLoopback {
```

### `openharmony/ets/api/@ohos.file.fs.d.ts`

用途：openSync/closeSync/fd
大小：311 KB（超过 200 KB，只出顶层声明、不摘 JSDoc 与类成员）

```ts
L29: declare namespace fileIo {
L127: namespace OpenMode {
L136: const READ_ONLY = 0o0;
L145: const WRITE_ONLY = 0o1;
L154: const READ_WRITE = 0o2;
L163: const CREATE = 0o100;
L173: const TRUNC = 0o1000;
L182: const APPEND = 0o2000;
L191: const NONBLOCK = 0o4000;
L199: const DIR = 0o200000;
L207: const NOFOLLOW = 0o400000;
L215: const SYNC = 0o4010000;
L224: const UNCACHE = 0o10000000000;
L256: declare function access(path: string, mode?: AccessModeType): Promise<boolean>;
L280: declare function access(path: string, callback: AsyncCallback<boolean>): void;
L308: declare function access(path: string, mode: AccessModeType, flag: AccessFlagType): Promise<boolean>;
L336: declare function accessSync(path: string, mode?: AccessModeType): boolean;
L363: declare function accessSync(path: string, mode: AccessModeType, flag: AccessFlagType): boolean;
L381: declare function close(file: number | File): Promise<void>;
L399: declare function close(file: number | File, callback: AsyncCallback<void>): void;
L416: declare function closeSync(file: number | File): void;
L461: declare function copy(srcUri: string, destUri: string, options?: CopyOptions): Promise<void>;
L501: declare function copy(srcUri: string, destUri: string, callback: AsyncCallback<void>): void;
L542: declare function copy(srcUri: string, destUri: string, options: CopyOptions, callback: AsyncCallback<void>): void;
L580: declare function copyDir(src: string, dest: string, mode?: number): Promise<void>;
L609: declare function copyDir(src: string, dest: string, callback: AsyncCallback<void>): void;
L627: declare function copyDir(src: string, dest: string, callback: AsyncCallback<void, Array<ConflictFiles>>): void;
L668: declare function copyDir(src: string, dest: string, mode: number, callback: AsyncCallback<void>): void;
L690: declare function copyDir(src: string, dest: string, mode: number, callback: AsyncCallback<void, Array<ConflictFiles>>): void;
L728: declare function copyDirSync(src: string, dest: string, mode?: number): void;
L761: declare function copyFile(src: string | number, dest: string | number, mode?: number): Promise<void>;
L791: declare function copyFile(src: string | number, dest: string | number, callback: AsyncCallback<void>): void;
L823: declare function copyFile(src: string | number, dest: string | number, mode: number, callback: AsyncCallback<void>): void;
L855: declare function copyFileSync(src: string | number, dest: string | number, mode?: number): void;
L902: declare function createStream(path: string, mode: string): Promise<Stream>;
L948: declare function createStream(path: string, mode: string, callback: AsyncCallback<Stream>): void;
L995: declare function createStreamSync(path: string, mode: string): Stream;
L1054: declare function createRandomAccessFile(file: string | File, mode?: number, options?: RandomAccessFileOptions): Promise<RandomAccessFile>;
L1092: declare function createRandomAccessFile(file: string | File, callback: AsyncCallback<RandomAccessFile>): void;
L1145: declare function createRandomAccessFile(file: string | File, mode: number, callback: AsyncCallback<RandomAccessFile>): void;
L1203: declare function createRandomAccessFileSync(file: string | File, mode?: number, options?: RandomAccessFileOptions): RandomAccessFile;
L1233: declare function createReadStream(path: string, options?: ReadStreamOptions): ReadStream;
L1265: declare function createWriteStream(path: string, options?: WriteStreamOptions): WriteStream;
L1291: declare function createWatcher(path: string, events: number, listener: WatchEventListener): Watcher;
L1307: declare function dup(fd: number): File;
L1324: declare function fdatasync(fd: number): Promise<void>;
L1341: declare function fdatasync(fd: number, callback: AsyncCallback<void>): void;
L1357: declare function fdatasyncSync(fd: number): void;
L1404: declare function fdopenStream(fd: number, mode: string): Promise<Stream>;
L1451: declare function fdopenStream(fd: number, mode: string, callback: AsyncCallback<Stream>): void;
L1498: declare function fdopenStreamSync(fd: number, mode: string): Stream;
L1515: declare function fsync(fd: number): Promise<void>;
L1532: declare function fsync(fd: number, callback: AsyncCallback<void>): void;
L1548: declare function fsyncSync(fd: number): void;
L1571: declare function listFile(path: string, options?: ListFileOptions): Promise<string[]>;
L1592: declare function listFile(path: string, callback: AsyncCallback<string[]>): void;
L1615: declare function listFile(path: string, options: ListFileOptions, callback: AsyncCallback<string[]>): void;
L1637: declare function listFileSync(path: string, options?: ListFileOptions): string[];
L1654: declare function listFileExt(path: string, options?: ListFileExtOptions): Promise<string[]>;
L1671: declare function listFileExtSync(path: string, options?: ListFileExtOptions): string[];
L1689: declare function lseek(fd: number, offset: number, whence?: WhenceType): number;
L1711: declare function lstat(path: string): Promise<Stat>;
L1733: declare function lstat(path: string, callback: AsyncCallback<Stat>): void;
L1755: declare function lstatSync(path: string): Stat;
L1781: declare function mkdir(path: string): Promise<void>;
L1810: declare function mkdir(path: string, recursion: boolean): Promise<void>;
L1836: declare function mkdir(path: string, callback: AsyncCallback<void>): void;
L1865: declare function mkdir(path: string, recursion: boolean, callback: AsyncCallback<void>): void;
L1890: declare function mkdirSync(path: string): void;
L1918: declare function mkdirSync(path: string, recursion: boolean): void;
L1944: declare function mkdtemp(prefix: string): Promise<string>;
L1970: declare function mkdtemp(prefix: string, callback: AsyncCallback<string>): void;
L1996: declare function mkdtempSync(prefix: string): string;
L2035: declare function mmap(file: number | File, mode: MappingMode, offset: number, size: number): Promise<FileMapping>;
L2074: declare function mmapSync(file: number | File, mode: MappingMode, offset: number, size: number): FileMapping;
L2122: declare function moveDir(src: string, dest: string, mode?: number): Promise<void>;
L2151: declare function moveDir(src: string, dest: string, callback: AsyncCallback<void>): void;
L2170: declare function moveDir(src: string, dest: string, callback: AsyncCallback<void, Array<ConflictFiles>>): void;
L2219: declare function moveDir(src: string, dest: string, mode: number, callback: AsyncCallback<void>): void;
L2250: declare function moveDir(src: string, dest: string, mode: number, callback: AsyncCallback<void, Array<ConflictFiles>>): void;
L2297: declare function moveDirSync(src: string, dest: string, mode?: number): void;
L2333: declare function moveFile(src: string, dest: string, mode?: number): Promise<void>;
L2368: declare function moveFile(src: string, dest: string, callback: AsyncCallback<void>): void;
L2404: declare function moveFile(src: string, dest: string, mode: number, callback: AsyncCallback<void>): void;
L2439: declare function moveFileSync(src: string, dest: string, mode?: number): void;
L2491: declare function open(path: string, mode?: number): Promise<File>;
L2529: declare function open(path: string, callback: AsyncCallback<File>): void;
L2582: declare function open(path: string, mode: number, callback: AsyncCallback<File>): void;
L2634: declare function openSync(path: string, mode?: number): File;
L2664: declare function read(fd: number, buffer: ArrayBuffer, options?: ReadOptions): Promise<number>;
L2685: declare function read(fd: number, buffer: ArrayBuffer, callback: AsyncCallback<number>): void;
L2714: declare function read(fd: number, buffer: ArrayBuffer, options: ReadOptions, callback: AsyncCallback<number>): void;
L2744: declare function readSync(fd: number, buffer: ArrayBuffer, options?: ReadOptions): number;
L2771: declare function readLines(filePath: string, options?: Options): Promise<ReaderIterator>;
L2794: declare function readLines(filePath: string, callback: AsyncCallback<ReaderIterator>): void;
L2820: declare function readLines(filePath: string, options: Options, callback: AsyncCallback<ReaderIterator>): void;
L2846: declare function readLinesSync(filePath: string, options?: Options): ReaderIterator;
L2881: declare function readText(filePath: string, options?: ReadTextOptions): Promise<string>;
L2905: declare function readText(filePath: string, callback: AsyncCallback<string>): void;
L2939: declare function readText(filePath: string, options: ReadTextOptions, callback: AsyncCallback<string>): void;
L2974: declare function readTextSync(filePath: string, options?: ReadTextOptions): string;
L3009: declare function rename(oldPath: string, newPath: string): Promise<void>;
L3044: declare function rename(oldPath: string, newPath: string, callback: AsyncCallback<void>): void;
L3078: declare function renameSync(oldPath: string, newPath: string): void;
L3105: declare function rmdir(path: string): Promise<void>;
L3133: declare function rmdir(path: string, callback: AsyncCallback<void>): void;
L3159: declare function rmdirSync(path: string): void;
L3184: declare function stat(file: string | number): Promise<Stat>;
L3210: declare function stat(file: string | number, callback: AsyncCallback<Stat>): void;
L3235: declare function statSync(file: string | number): Stat;
L3263: declare function symlink(target: string, srcPath: string): Promise<void>;
L3291: declare function symlink(target: string, srcPath: string, callback: AsyncCallback<void>): void;
L3318: declare function symlinkSync(target: string, srcPath: string): void;
L3346: declare function truncate(file: string | number, len?: number): Promise<void>;
L3373: declare function truncate(file: string | number, callback: AsyncCallback<void>): void;
L3402: declare function truncate(file: string | number, len: number, callback: AsyncCallback<void>): void;
L3429: declare function truncateSync(file: string | number, len?: number): void;
L3455: declare function unlink(path: string): Promise<void>;
L3481: declare function unlink(path: string, callback: AsyncCallback<void>): void;
L3506: declare function unlinkSync(path: string): void;
L3523: declare function utimes(path: string, mtime: number): void;
L3557: declare function write(fd: number, buffer: ArrayBuffer | string, options?: WriteOptions): Promise<number>;
L3582: declare function write(fd: number, buffer: ArrayBuffer | string, callback: AsyncCallback<number>): void;
L3617: declare function write(fd: number, buffer: ArrayBuffer | string, options: WriteOptions, callback: AsyncCallback<number>): void;
L3651: declare function writeSync(fd: number, buffer: ArrayBuffer | string, options?: WriteOptions): number;
L3671: declare function connectDfs(networkId: string, listeners: DfsListeners): Promise<void>;
L3688: declare function disconnectDfs(networkId: string): Promise<void>;
L3712: declare function setxattr(path: string, key: string, value: string): Promise<void>;
L3735: declare function setxattrSync(path: string, key: string, value: string): void;
L3755: declare function getxattr(path: string, key: string): Promise<string>;
L3775: declare function getxattrSync(path: string, key: string): string;
L3782: interface Progress {
L3804: export class TaskSignal {
L3838: interface CopyOptions {
L3861: type ProgressListener = (progress: Progress) => void;
L3870: declare interface File {
L3997: declare interface FileMapping {
L4262: declare interface RandomAccessFile {
L4576: declare class ReadStream extends stream.Readable {
L4644: declare class WriteStream extends stream.Writable {
L4714: export class AtomicFile {
L4824: declare interface Stat {
L5068: declare interface Stream {
L5423: export interface WatchEventListener {
L5441: export interface WatchEvent {
L5478: export interface Watcher {
L5529: export interface ReaderIteratorResult {
L5556: declare interface ReaderIterator {
L5578: export interface Filter {
L5646: export interface ConflictFiles {
L5671: export interface Options {
L5689: export interface ReadOptions {
L5718: export interface ReadTextOptions extends ReadOptions {
L5738: export interface WriteOptions extends Options {
L5766: export interface ListFileOptions {
L5803: export interface FileFilter {
L5824: export interface ListFileExtOptions {
L5862: export interface RandomAccessFileOptions {
L5888: export interface ReadStreamOptions {
L5914: export interface WriteStreamOptions {
L5957: export interface DfsListeners {
L5980: declare enum MappingMode {
L6016: declare enum WhenceType {
L6048: declare enum LocationType {
L6072: declare enum AccessModeType {
L6116: declare enum AccessFlagType {
```

### `openharmony/ets/api/@ohos.file.fileuri.d.ts`

用途：FileUri 与 uri→path
大小：6 KB（含类/接口成员）

```ts
  // @since 15 | @atomicservice | @syscap SystemCapability.FileManagement.AppFileService | @since 9
L35: declare namespace fileUri {
  // @since 15 | @atomicservice | @syscap SystemCapability.FileManagement.AppFileService | @since 10
L51: class FileUri extends uri.URI {
  // @since 15 | @atomicservice | @syscap SystemCapability.FileManagement.AppFileService | @since 10
L75: constructor(uriOrPath: string);
  // @since 15 | @atomicservice | @syscap SystemCapability.FileManagement.AppFileService | @since 10
L99: get name(): string;
  // @since 15 | @atomicservice | @syscap SystemCapability.FileManagement.AppFileService | @since 11 | @since 10
L121: getFullDirectoryUri(): string;
  // @since 15 | @atomicservice | @syscap SystemCapability.FileManagement.AppFileService | @since 12 | @since 11 | @since 10
L139: isRemoteUri(): boolean;
  // @since 15 | @atomicservice | @syscap SystemCapability.FileManagement.AppFileService | @since 9 | @since 12 | @since 11
L162: function getUriFromPath(path: string): string;
```

### `openharmony/ets/api/@ohos.data.relationalStore.d.ts`

用途：关系型数据库全量签名
大小：473 KB（超过 200 KB，只出顶层声明、不摘 JSDoc 与类成员）

```ts
L63: declare namespace relationalStore {
L71: enum AssetStatus {
L136: interface Asset {
L206: type Assets = Asset[];
L224: type ValueType = null | number | string | boolean | Uint8Array | Asset | Assets | Float32Array | bigint;
L232: type ValuesBucket = Record<string, ValueType>;
L243: type PRIKeyType = number | string;
L250: type UTCTime = Date;
L257: type ModifyTime = Map<PRIKeyType, UTCTime>;
L266: type RowData = Array<ValueType>;
L275: type RowsData = Array<RowData>;
L283: interface StoreConfig {
L520: interface CryptoParam {
L600: enum EncryptionAlgo {
L633: enum HmacAlgo {
L666: enum KdfAlgo {
L709: enum Tokenizer {
L747: enum Progress {
L776: interface Statistic {
L812: interface TableDetails {
L834: enum ProgressCode {
L909: interface ProgressDetails {
L949: interface SqlExecutionInfo {
L1000: interface ExceptionMessage {
L1034: interface SqlInfo {
L1066: enum SecurityLevel {
L1110: enum SyncMode {
L1158: enum SubscribeType {
L1199: enum ChangeType {
L1223: interface ChangeInfo {
L1271: enum DistributedTableType {
L1298: enum DistributedType {
L1326: enum AssetConflictPolicy {
L1358: interface DistributedConfig {
L1439: interface CloudSyncConfig {
L1473: enum ConflictResolution {
L1533: enum Origin {
L1563: enum Field {
L1633: enum RebuildType {
L1664: enum TransactionType {
L1703: interface TransactionOptions {
L1722: enum ColumnType {
L1810: interface ReturningConfig {
L1841: interface Result {
L1871: enum SyncResultCode {
L1976: interface SyncResult {
L2011: class RdbPredicates {
L2485: interface ResultSet {
L3359: class LiteResultSet {
L3789: interface RdbStore {
L6500: interface Transaction {
L7452: function getRdbStore(context: Context, config: StoreConfig, callback: AsyncCallback<RdbStore>): void;
L7497: function getRdbStore(context: Context, config: StoreConfig): Promise<RdbStore>;
L7524: function getRdbStoreSync(context: Context, config: StoreConfig): RdbStore;
L7549: function deleteRdbStore(context: Context, name: string, callback: AsyncCallback<void>): void;
L7577: function deleteRdbStore(context: Context, config: StoreConfig, callback: AsyncCallback<void>): void;
L7602: function deleteRdbStore(context: Context, name: string): Promise<void>;
L7631: function deleteRdbStore(context: Context, config: StoreConfig): Promise<void>;
L7639: function isVectorSupported(): boolean;
L7652: function isTokenizerSupported(tokenizer: Tokenizer): boolean;
L7668: function getInsertSqlInfo(table: string, values: ValuesBucket, conflict?: ConflictResolution): SqlInfo;
L7684: function getUpdateSqlInfo(predicates: RdbPredicates, values: ValuesBucket, conflict?: ConflictResolution): SqlInfo;
L7696: function getDeleteSqlInfo(predicates: RdbPredicates): SqlInfo;
L7710: function getQuerySqlInfo(predicates: RdbPredicates, columns?: Array<string>): SqlInfo;
```

### `openharmony/ets/api/@ohos.data.preferences.d.ts`

用途：首选项
大小：65 KB（含类/接口成员）

```ts
  // @since 9 | @atomicservice [since 11] | @syscap SystemCapability.DistributedDataManager.Preferences.Core
L45: declare namespace preferences {
  // @since 9 | @atomicservice [since 11] | @syscap SystemCapability.DistributedDataManager.Preferences.Core
L62: type ValueType = number | string | boolean | Array<number> | Array<string> | Array<boolean> | Uint8Array | object | bigint;
  // @since 9 | @atomicservice [since 11] | @syscap SystemCapability.DistributedDataManager.Preferences.Core
L71: const MAX_KEY_LENGTH: number;
  // @since 9 | @atomicservice [since 11] | @syscap SystemCapability.DistributedDataManager.Preferences.Core
L80: const MAX_VALUE_LENGTH: number;
  // @since 18 | @atomicservice | @syscap SystemCapability.DistributedDataManager.Preferences.Core
L102: enum StorageType {
  // @since 10 | @atomicservice [since 11] | @syscap SystemCapability.DistributedDataManager.Preferences.Core | @since 18 | @atomicservice
L134: interface Options {
  // @since 10 | @atomicservice [since 11] | @syscap SystemCapability.DistributedDataManager.Preferences.Core
L146: name: string;
  // @since 9 | @atomicservice [since 11] | @syscap SystemCapability.DistributedDataManager.Preferences.Core | @since 18 | @atomicservice | @since 10 | @StageModelOnly
L197: function getPreferences(context: Context, name: string, callback: AsyncCallback<Preferences>): void;
  // @since 10 | @atomicservice [since 11] | @syscap SystemCapability.DistributedDataManager.Preferences.Core
L221: function getPreferences(context: Context, options: Options, callback: AsyncCallback<Preferences>): void;
  // @since 9 | @atomicservice [since 11] | @syscap SystemCapability.DistributedDataManager.Preferences.Core
L240: function getPreferences(context: Context, name: string): Promise<Preferences>;
  // @since 10 | @atomicservice [since 11] | @syscap SystemCapability.DistributedDataManager.Preferences.Core
L262: function getPreferences(context: Context, options: Options): Promise<Preferences>;
  // @since 10 | @atomicservice [since 11] | @syscap SystemCapability.DistributedDataManager.Preferences.Core
L284: function getPreferencesSync(context: Context, options: Options): Preferences;
  // @since 18 | @atomicservice | @syscap SystemCapability.DistributedDataManager.Preferences.Core
L296: function isStorageTypeSupported(type: StorageType): boolean;
  // @since 9 | @atomicservice [since 11] | @syscap SystemCapability.DistributedDataManager.Preferences.Core
L321: function deletePreferences(context: Context, name: string, callback: AsyncCallback<void>): void;
  // @since 10 | @atomicservice [since 11] | @syscap SystemCapability.DistributedDataManager.Preferences.Core
L349: function deletePreferences(context: Context, options: Options, callback: AsyncCallback<void>): void;
  // @since 9 | @atomicservice [since 11] | @syscap SystemCapability.DistributedDataManager.Preferences.Core
L373: function deletePreferences(context: Context, name: string): Promise<void>;
  // @since 10 | @atomicservice [since 11] | @syscap SystemCapability.DistributedDataManager.Preferences.Core
L400: function deletePreferences(context: Context, options: Options): Promise<void>;
  // @since 9 | @atomicservice [since 11] | @syscap SystemCapability.DistributedDataManager.Preferences.Core
L435: function removePreferencesFromCache(context: Context, name: string, callback: AsyncCallback<void>): void;
  // @since 10 | @atomicservice [since 11] | @syscap SystemCapability.DistributedDataManager.Preferences.Core
L473: function removePreferencesFromCache(context: Context, options: Options, callback: AsyncCallback<void>): void;
  // @since 9 | @atomicservice [since 11] | @syscap SystemCapability.DistributedDataManager.Preferences.Core
L507: function removePreferencesFromCache(context: Context, name: string): Promise<void>;
  // @since 10 | @atomicservice [since 11] | @syscap SystemCapability.DistributedDataManager.Preferences.Core
L544: function removePreferencesFromCache(context: Context, options: Options): Promise<void>;
  // @since 10 | @atomicservice [since 11] | @syscap SystemCapability.DistributedDataManager.Preferences.Core
L577: function removePreferencesFromCacheSync(context: Context, name: string): void;
  // @since 10 | @atomicservice [since 11] | @syscap SystemCapability.DistributedDataManager.Preferences.Core
L613: function removePreferencesFromCacheSync(context: Context, options: Options): void;
  // @since 9 | @atomicservice [since 11] | @syscap SystemCapability.DistributedDataManager.Preferences.Core
L625: interface Preferences {
  // @since 9 | @atomicservice [since 11] | @syscap SystemCapability.DistributedDataManager.Preferences.Core
L645: get(key: string, defValue: ValueType, callback: AsyncCallback<ValueType>): void;
  // @since 9 | @atomicservice [since 11] | @syscap SystemCapability.DistributedDataManager.Preferences.Core
L664: get(key: string, defValue: ValueType): Promise<ValueType>;
  // @since 10 | @atomicservice [since 11] | @syscap SystemCapability.DistributedDataManager.Preferences.Core | @since 9
L683: getSync(key: string, defValue: ValueType): ValueType;
  // @since 9 | @atomicservice [since 11] | @syscap SystemCapability.DistributedDataManager.Preferences.Core | @since 10
L697: getAll(callback: AsyncCallback<Object>): void;
  // @since 9 | @atomicservice [since 11] | @syscap SystemCapability.DistributedDataManager.Preferences.Core | @since 10
L708: getAll(): Promise<Object>;
  // @since 10 | @atomicservice [since 11] | @syscap SystemCapability.DistributedDataManager.Preferences.Core | @since 9
L719: getAllSync(): Object;
  // @since 9 | @atomicservice [since 11] | @syscap SystemCapability.DistributedDataManager.Preferences.Core | @since 10
L738: has(key: string, callback: AsyncCallback<boolean>): void;
  // @since 9 | @atomicservice [since 11] | @syscap SystemCapability.DistributedDataManager.Preferences.Core | @since 10
L757: has(key: string): Promise<boolean>;
  // @since 10 | @atomicservice [since 11] | @syscap SystemCapability.DistributedDataManager.Preferences.Core | @since 9
L776: hasSync(key: string): boolean;
  // @since 9 | @atomicservice [since 11] | @syscap SystemCapability.DistributedDataManager.Preferences.Core | @since 10
L797: put(key: string, value: ValueType, callback: AsyncCallback<void>): void;
  // @since 9 | @atomicservice [since 11] | @syscap SystemCapability.DistributedDataManager.Preferences.Core | @since 10
L817: put(key: string, value: ValueType): Promise<void>;
  // @since 10 | @atomicservice [since 11] | @syscap SystemCapability.DistributedDataManager.Preferences.Core | @since 9
L836: putSync(key: string, value: ValueType): void;
  // @since 9 | @atomicservice [since 11] | @syscap SystemCapability.DistributedDataManager.Preferences.Core | @since 10
L856: delete(key: string, callback: AsyncCallback<void>): void;
  // @since 9 | @atomicservice [since 11] | @syscap SystemCapability.DistributedDataManager.Preferences.Core | @since 10
L875: delete(key: string): Promise<void>;
  // @since 10 | @atomicservice [since 11] | @syscap SystemCapability.DistributedDataManager.Preferences.Core | @since 9
L893: deleteSync(key: string): void;
  // @since 9 | @atomicservice [since 11] | @syscap SystemCapability.DistributedDataManager.Preferences.Core | @since 10
L908: clear(callback: AsyncCallback<void>): void;
  // @since 9 | @atomicservice [since 11] | @syscap SystemCapability.DistributedDataManager.Preferences.Core | @since 10
L921: clear(): Promise<void>;
  // @since 10 | @atomicservice [since 11] | @syscap SystemCapability.DistributedDataManager.Preferences.Core | @since 9
L932: clearSync(): void;
  // @since 9 | @atomicservice [since 11] | @syscap SystemCapability.DistributedDataManager.Preferences.Core | @since 10
L946: flush(callback: AsyncCallback<void>): void;
  // @since 9 | @atomicservice [since 11] | @syscap SystemCapability.DistributedDataManager.Preferences.Core | @since 10
L958: flush(): Promise<void>;
  // @since 14 | @atomicservice | @syscap SystemCapability.DistributedDataManager.Preferences.Core | @since 9 | @atomicservice [since 11] | @since 10
L968: flushSync(): void;
  // @since 9 | @atomicservice [since 11] | @syscap SystemCapability.DistributedDataManager.Preferences.Core | @since 14 | @atomicservice | @since 10
L987: on(type: 'change', callback: Callback<string>): void;
  // @since 10 | @atomicservice [since 11] | @syscap SystemCapability.DistributedDataManager.Preferences.Core | @since 9 | @since 14 | @atomicservice
L1010: on(type: 'multiProcessChange', callback: Callback<string>): void;
  // @since 12 | @atomicservice | @syscap SystemCapability.DistributedDataManager.Preferences.Core | @since 10 | @atomicservice [since 11] | @since 9 | @since 14
L1030: on(type: 'dataChange', keys: Array<string>, callback: Callback<Record<string, ValueType>>): void;
  // @since 9 | @atomicservice [since 11] | @syscap SystemCapability.DistributedDataManager.Preferences.Core | @since 12 | @atomicservice | @since 10
L1051: off(type: 'change', callback?: Callback<string>): void;
  // @since 10 | @atomicservice [since 11] | @syscap SystemCapability.DistributedDataManager.Preferences.Core | @since 9 | @since 12 | @atomicservice
L1073: off(type: 'multiProcessChange', callback?: Callback<string>): void;
  // @since 12 | @atomicservice | @syscap SystemCapability.DistributedDataManager.Preferences.Core | @since 10 | @atomicservice [since 11] | @since 9
L1092: off(type: 'dataChange', keys: Array<string>, callback?: Callback<Record<string, ValueType>>): void;
```

### `openharmony/ets/api/@ohos.data.uniformTypeDescriptor.d.ts`

用途：UTD 类型定义
大小：68 KB（含类/接口成员）

```ts
  // @since 10 | @atomicservice [since 11] | @stagemodelonly | @syscap SystemCapability.DistributedDataManager.UDMF.Core
L28: declare namespace uniformTypeDescriptor {
  // @since 10 | @atomicservice [since 11] | @stagemodelonly | @syscap SystemCapability.DistributedDataManager.UDMF.Core
L41: enum UniformDataType {
  // @since 11 | @stagemodelonly | @syscap SystemCapability.DistributedDataManager.UDMF.Core | @since 15 | @since 12
L1844: class TypeDescriptor {
  // @since 11 | @stagemodelonly | @syscap SystemCapability.DistributedDataManager.UDMF.Core
L1855: get typeId(): string;
  // @since 11 | @stagemodelonly | @syscap SystemCapability.DistributedDataManager.UDMF.Core
L1866: set typeId(value: string);
  // @since 11 | @stagemodelonly | @syscap SystemCapability.DistributedDataManager.UDMF.Core
L1877: get belongingToTypes(): Array<string>;
  // @since 11 | @stagemodelonly | @syscap SystemCapability.DistributedDataManager.UDMF.Core
L1888: set belongingToTypes(value: Array<string>);
  // @since 11 | @stagemodelonly | @syscap SystemCapability.DistributedDataManager.UDMF.Core
L1899: get description(): string;
  // @since 11 | @stagemodelonly | @syscap SystemCapability.DistributedDataManager.UDMF.Core
L1910: set description(value: string);
  // @since 11 | @stagemodelonly | @syscap SystemCapability.DistributedDataManager.UDMF.Core
L1921: get referenceURL(): string;
  // @since 11 | @stagemodelonly | @syscap SystemCapability.DistributedDataManager.UDMF.Core
L1932: set referenceURL(value: string);
  // @since 11 | @stagemodelonly | @syscap SystemCapability.DistributedDataManager.UDMF.Core
L1943: get iconFile(): string;
  // @since 11 | @stagemodelonly | @syscap SystemCapability.DistributedDataManager.UDMF.Core
L1954: set iconFile(value: string);
  // @since 12 | @stagemodelonly | @syscap SystemCapability.DistributedDataManager.UDMF.Core | @since 11
L1965: get filenameExtensions(): Array<string>;
  // @since 12 | @stagemodelonly | @syscap SystemCapability.DistributedDataManager.UDMF.Core | @since 11
L1976: set filenameExtensions(value: Array<string>);
  // @since 12 | @stagemodelonly | @syscap SystemCapability.DistributedDataManager.UDMF.Core | @since 11
L1987: get mimeTypes(): Array<string>;
  // @since 12 | @stagemodelonly | @syscap SystemCapability.DistributedDataManager.UDMF.Core | @since 11
L1998: set mimeTypes(value: Array<string>);
  // @since 11 | @stagemodelonly | @syscap SystemCapability.DistributedDataManager.UDMF.Core | @since 12
L2014: belongsTo(type: string): boolean;
  // @since 11 | @stagemodelonly | @syscap SystemCapability.DistributedDataManager.UDMF.Core | @since 12
L2032: isLowerLevelType(type: string): boolean;
  // @since 11 | @stagemodelonly | @syscap SystemCapability.DistributedDataManager.UDMF.Core | @since 12
L2050: isHigherLevelType(type: string): boolean;
  // @since 11 | @stagemodelonly | @syscap SystemCapability.DistributedDataManager.UDMF.Core | @since 12
L2065: equals(typeDescriptor: TypeDescriptor): boolean;
  // @since 11 | @stagemodelonly | @syscap SystemCapability.DistributedDataManager.UDMF.Core
L2081: function getTypeDescriptor(typeId: string): TypeDescriptor;
  // @since 11 | @stagemodelonly | @syscap SystemCapability.DistributedDataManager.UDMF.Core
L2102: function getUniformDataTypeByFilenameExtension(filenameExtension: string, belongsTo?: string): string;
  // @since 11 | @stagemodelonly | @syscap SystemCapability.DistributedDataManager.UDMF.Core
L2122: function getUniformDataTypeByMIMEType(mimeType: string, belongsTo?: string): string;
  // @since 13 | @stagemodelonly | @syscap SystemCapability.DistributedDataManager.UDMF.Core
L2142: function getUniformDataTypesByFilenameExtension(filenameExtension: string, belongsTo?: string): Array<string>;
  // @since 13 | @stagemodelonly | @syscap SystemCapability.DistributedDataManager.UDMF.Core
L2161: function getUniformDataTypesByMIMEType(mimeType: string, belongsTo?: string): Array<string>;
```

### `openharmony/ets/api/@ohos.notificationManager.d.ts`

用途：通知授权与发布
大小：60 KB（含类/接口成员）

```ts
  // @since 9 | @atomicservice [since 12] | @syscap SystemCapability.Notification.Notification
L48: declare namespace notificationManager {
  // @since 9 | @syscap SystemCapability.Notification.Notification
L81: function publish(request: NotificationRequest, callback: AsyncCallback<void>): void;
  // @since 9 | @syscap SystemCapability.Notification.Notification
L113: function publish(request: NotificationRequest): Promise<void>;
  // @since 9 | @syscap SystemCapability.Notification.Notification
L130: function cancel(id: number, callback: AsyncCallback<void>): void;
  // @since 9 | @syscap SystemCapability.Notification.Notification
L148: function cancel(id: number, label: string, callback: AsyncCallback<void>): void;
  // @since 9 | @syscap SystemCapability.Notification.Notification
L164: function cancel(id: number, label?: string): Promise<void>;
  // @since 9 | @syscap SystemCapability.Notification.Notification
L179: function cancelAll(callback: AsyncCallback<void>): void;
  // @since 9 | @syscap SystemCapability.Notification.Notification
L191: function cancelAll(): Promise<void>;
  // @since 9 | @syscap SystemCapability.Notification.Notification
L207: function addSlot(type: SlotType, callback: AsyncCallback<void>): void;
  // @since 9 | @syscap SystemCapability.Notification.Notification
L222: function addSlot(type: SlotType): Promise<void>;
  // @since 9 | @syscap SystemCapability.Notification.Notification
L239: function getSlot(slotType: SlotType, callback: AsyncCallback<NotificationSlot>): void;
  // @since 9 | @syscap SystemCapability.Notification.Notification
L254: function getSlot(slotType: SlotType): Promise<NotificationSlot>;
  // @since 9 | @syscap SystemCapability.Notification.Notification
L269: function getSlots(callback: AsyncCallback<Array<NotificationSlot>>): void;
  // @since 9 | @syscap SystemCapability.Notification.Notification
L280: function getSlots(): Promise<Array<NotificationSlot>>;
  // @since 9 | @syscap SystemCapability.Notification.Notification
L297: function removeSlot(slotType: SlotType, callback: AsyncCallback<void>): void;
  // @since 9 | @syscap SystemCapability.Notification.Notification
L312: function removeSlot(slotType: SlotType): Promise<void>;
  // @since 9 | @syscap SystemCapability.Notification.Notification
L326: function removeAllSlots(callback: AsyncCallback<void>): void;
  // @since 9 | @syscap SystemCapability.Notification.Notification
L337: function removeAllSlots(): Promise<void>;
  // @since 11 | @syscap SystemCapability.Notification.Notification
L356: function isNotificationEnabled(callback: AsyncCallback<boolean>): void;
  // @since 11 | @syscap SystemCapability.Notification.Notification
L371: function isNotificationEnabled(): Promise<boolean>;
  // @since 12 | @syscap SystemCapability.Notification.Notification
L383: function isNotificationEnabledSync(): boolean;
  // @since 9 | @syscap SystemCapability.Notification.Notification
L399: function getActiveNotificationCount(callback: AsyncCallback<number>): void;
  // @since 9 | @syscap SystemCapability.Notification.Notification
L410: function getActiveNotificationCount(): Promise<number>;
  // @since 9 | @syscap SystemCapability.Notification.Notification
L425: function getActiveNotifications(callback: AsyncCallback<Array<NotificationRequest>>): void;
  // @since 9 | @syscap SystemCapability.Notification.Notification
L436: function getActiveNotifications(): Promise<Array<NotificationRequest>>;
  // @since 24 | @stagemodelonly | @syscap SystemCapability.Notification.Notification
L453: function getNotificationParameters(id: number, label?: string): Promise<NotificationParameters>;
  // @since 9 | @syscap SystemCapability.Notification.Notification
L471: function cancelGroup(groupName: string, callback: AsyncCallback<void>): void;
  // @since 9 | @syscap SystemCapability.Notification.Notification
L487: function cancelGroup(groupName: string): Promise<void>;
  // @since 9 | @syscap SystemCapability.Notification.Notification
L505: function isSupportTemplate(templateName: string, callback: AsyncCallback<boolean>): void;
  // @since 9 | @syscap SystemCapability.Notification.Notification
L522: function isSupportTemplate(templateName: string): Promise<boolean>;
  // @deprecated since 12 | @since 9 | @syscap SystemCapability.Notification.Notification
L548: function requestEnableNotification(callback: AsyncCallback<void>): void;
  // @since 10 | @StageModelOnly | @syscap SystemCapability.Notification.Notification
L580: function requestEnableNotification(context: UIAbilityContext, callback: AsyncCallback<void>): void;
  // @deprecated since 12 | @since 9 | @syscap SystemCapability.Notification.Notification
L602: function requestEnableNotification(): Promise<void>;
  // @since 10 | @StageModelOnly | @syscap SystemCapability.Notification.Notification
L633: function requestEnableNotification(context: UIAbilityContext): Promise<void>;
  // @deprecated since 26.0.0 | @since 9 | @syscap SystemCapability.Notification.Notification
L653: function isDistributedEnabled(callback: AsyncCallback<boolean>): void;
  // @deprecated since 26.0.0 | @since 9 | @syscap SystemCapability.Notification.Notification
L669: function isDistributedEnabled(): Promise<boolean>;
  // @since 10 | @syscap SystemCapability.Notification.Notification
L688: function setBadgeNumber(badgeNumber: number, callback: AsyncCallback<void>): void;
  // @since 10 | @syscap SystemCapability.Notification.Notification
L706: function setBadgeNumber(badgeNumber: number): Promise<void>;
  // @since 20 | @syscap SystemCapability.Notification.Notification
L717: function getNotificationSetting(): Promise<NotificationSetting>;
  // @since 13 | @stagemodelonly | @syscap SystemCapability.Notification.NotificationSettings
L732: function openNotificationSettings(context: UIAbilityContext): Promise<void>;
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.Notification.NotificationSettings
L748: function openNotificationSettingsWithResult(context: UIAbilityContext): Promise<NotificationSetting>;
  // @since 22 | @syscap SystemCapability.Notification.Notification
L760: function getBadgeNumber(): Promise<number>;
  // @since 23 | @syscap SystemCapability.Notification.Notification
L773: function isGeofenceEnabled(): Promise<boolean>;
  // @since 20 | @syscap SystemCapability.Notification.Notification
L780: export interface NotificationSetting {
  // @since 20 | @syscap SystemCapability.Notification.Notification
L790: vibrationEnabled: boolean;
  // @since 20 | @syscap SystemCapability.Notification.Notification
L800: soundEnabled: boolean;
  // @since 9 | @atomicservice [since 12] | @syscap SystemCapability.Notification.Notification | @since 26.0.0 | @stagemodelonly | @since 20
L853: export enum SlotType {
  // @since 9 | @atomicservice [since 12] | @syscap SystemCapability.Notification.Notification | @since 11
L928: export enum ContentType {
  // @since 9 | @syscap SystemCapability.Notification.Notification | @since 11 | @atomicservice [since 12]
L997: export enum SlotLevel {
  // @since 23 | @syscap SystemCapability.Notification.Notification | @since 9
L1042: export enum PriorityNotificationType {
  // @since 9 | @syscap SystemCapability.Notification.Notification | @since 23
L1085: export type BundleOption = _BundleOption;
  // @since 9 | @syscap SystemCapability.Notification.Notification
L1092: export type NotificationActionButton = _NotificationActionButton;
  // @since 9 | @syscap SystemCapability.Notification.Notification
L1100: export type NotificationBasicContent = _NotificationBasicContent;
  // @since 9 | @syscap SystemCapability.Notification.Notification
L1108: export type NotificationContent = _NotificationContent;
  // @since 9 | @syscap SystemCapability.Notification.Notification
L1116: export type NotificationLongTextContent = _NotificationLongTextContent;
  // @since 9 | @syscap SystemCapability.Notification.Notification
L1124: export type NotificationMultiLineContent = _NotificationMultiLineContent;
  // @since 9 | @syscap SystemCapability.Notification.Notification
L1131: export type NotificationPictureContent = _NotificationPictureContent;
  // @since 11 | @syscap SystemCapability.Notification.Notification
L1138: export type NotificationSystemLiveViewContent = _NotificationSystemLiveViewContent;
  // @since 9 | @syscap SystemCapability.Notification.Notification
L1146: export type NotificationRequest = _NotificationRequest;
  // @since 9 | @syscap SystemCapability.Notification.Notification
L1153: export type DistributedOptions = _DistributedOptions;
  // @since 9 | @syscap SystemCapability.Notification.Notification
L1160: export type NotificationSlot = _NotificationSlot;
  // @since 9 | @syscap SystemCapability.Notification.Notification
L1167: export type NotificationTemplate = _NotificationTemplate;
  // @since 9 | @syscap SystemCapability.Notification.Notification
L1174: export type NotificationUserInput = _NotificationUserInput;
  // @since 11 | @syscap SystemCapability.Notification.Notification
L1181: export type NotificationCapsule = _NotificationCapsule;
  // @since 11 | @syscap SystemCapability.Notification.Notification
L1188: export type NotificationButton = _NotificationButton;
  // @since 11 | @syscap SystemCapability.Notification.Notification
L1195: export type NotificationTime = _NotificationTime;
  // @since 11 | @syscap SystemCapability.Notification.Notification
L1202: export type NotificationProgress = _NotificationProgress;
  // @since 24 | @stagemodelonly | @syscap SystemCapability.Notification.Notification
L1210: export type NotificationParameters = _NotificationParameters;
```

### `openharmony/ets/api/@ohos.reminderAgentManager.d.ts`

用途：代理提醒
大小：40 KB（含类/接口成员）

```ts
  // @since 9 | @syscap SystemCapability.Notification.ReminderAgent
L32: declare namespace reminderAgentManager {
  // @since 9 | @syscap SystemCapability.Notification.ReminderAgent | @permission ohos.permission.PUBLISH_AGENT_REMINDER
L55: function publishReminder(reminderReq: ReminderRequest, callback: AsyncCallback<number>): void;
  // @since 9 | @syscap SystemCapability.Notification.ReminderAgent | @permission ohos.permission.PUBLISH_AGENT_REMINDER
L75: function publishReminder(reminderReq: ReminderRequest): Promise<number>;
  // @since 9 | @syscap SystemCapability.Notification.ReminderAgent
L92: function cancelReminder(reminderId: number, callback: AsyncCallback<void>): void;
  // @since 9 | @syscap SystemCapability.Notification.ReminderAgent
L107: function cancelReminder(reminderId: number): Promise<void>;
  // @since 23 | @syscap SystemCapability.Notification.ReminderAgent
L124: function cancelReminderOnDisplay(reminderId: number): Promise<void>;
  // @since 9 | @syscap SystemCapability.Notification.ReminderAgent
L137: function getValidReminders(callback: AsyncCallback<Array<ReminderRequest>>): void;
  // @since 9 | @syscap SystemCapability.Notification.ReminderAgent
L148: function getValidReminders(): Promise<Array<ReminderRequest>>;
  // @since 9 | @syscap SystemCapability.Notification.ReminderAgent
L160: function cancelAllReminders(callback: AsyncCallback<void>): void;
  // @since 9 | @syscap SystemCapability.Notification.ReminderAgent
L170: function cancelAllReminders(): Promise<void>;
  // @since 20 | @syscap SystemCapability.Notification.ReminderAgent | @permission ohos.permission.PUBLISH_AGENT_REMINDER
L190: function updateReminder(reminderId: number, reminderReq: ReminderRequest): Promise<void>;
  // @since 9 | @syscap SystemCapability.Notification.ReminderAgent
L202: function addNotificationSlot(slot: NotificationSlot, callback: AsyncCallback<void>): void;
  // @since 9 | @syscap SystemCapability.Notification.ReminderAgent
L212: function addNotificationSlot(slot: NotificationSlot): Promise<void>;
  // @since 9 | @syscap SystemCapability.Notification.ReminderAgent
L224: function removeNotificationSlot(slotType: notification.SlotType, callback: AsyncCallback<void>): void;
  // @since 9 | @syscap SystemCapability.Notification.ReminderAgent
L234: function removeNotificationSlot(slotType: notification.SlotType): Promise<void>;
  // @since 12 | @syscap SystemCapability.Notification.ReminderAgent
L251: function addExcludeDate(reminderId: number, date: Date): Promise<void>;
  // @since 12 | @syscap SystemCapability.Notification.ReminderAgent
L266: function deleteExcludeDates(reminderId: number): Promise<void>;
  // @since 12 | @syscap SystemCapability.Notification.ReminderAgent
L281: function getExcludeDates(reminderId: number): Promise<Array<Date>>;
  // @since 12 | @syscap SystemCapability.Notification.ReminderAgent
L292: function getAllValidReminders(): Promise<Array<ReminderInfo>>;
  // @since 23 | @stagemodelonly | @syscap SystemCapability.Notification.ReminderAgent | @permission ohos.permission.PUBLISH_AGENT_REMINDER
L305: function subscribeReminderState(callback: Callback<Array<ReminderState>>): Promise<void>;
  // @since 23 | @stagemodelonly | @syscap SystemCapability.Notification.ReminderAgent
L317: function unsubscribeReminderState(callback?: Callback<Array<ReminderState>>): Promise<void>;
  // @since 9 | @syscap SystemCapability.Notification.ReminderAgent
L324: export enum ActionButtonType {
  // @since 9 | @syscap SystemCapability.Notification.ReminderAgent
L347: export enum ReminderType {
  // @since 20 | @syscap SystemCapability.Notification.ReminderAgent | @since 9
L376: export enum RingChannel {
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.Notification.ReminderAgent | @since 23 | @since 20
L406: export enum TimeZoneType {
  // @since 9 | @syscap SystemCapability.Notification.ReminderAgent | @since 26.0.0 | @stagemodelonly
L438: interface ActionButton {
  // @since 9 | @syscap SystemCapability.Notification.ReminderAgent
L445: title: string;
  // @since 9 | @syscap SystemCapability.Notification.ReminderAgent | @since 11
L460: type: ActionButtonType;
  // @since 9 | @syscap SystemCapability.Notification.ReminderAgent | @since 11
L468: interface WantAgent {
  // @since 9 | @syscap SystemCapability.Notification.ReminderAgent
L475: pkgName: string;
  // @since 9 | @syscap SystemCapability.Notification.ReminderAgent
L482: abilityName: string;
  // @since 9 | @syscap SystemCapability.Notification.ReminderAgent | @since 12
L505: interface MaxScreenWantAgent {
  // @since 9 | @syscap SystemCapability.Notification.ReminderAgent
L512: pkgName: string;
  // @since 9 | @syscap SystemCapability.Notification.ReminderAgent
L519: abilityName: string;
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.Notification.ReminderAgent | @since 9
L529: interface NotificationRequestProxy {
  // @since 9 | @syscap SystemCapability.Notification.ReminderAgent | @since 26.0.0 | @stagemodelonly
L562: interface ReminderRequest {
  // @since 9 | @syscap SystemCapability.Notification.ReminderAgent
L569: reminderType: ReminderType;
  // @since 9 | @syscap SystemCapability.Notification.ReminderAgent | @since 26.0.0 | @stagemodelonly | @since 11 | @since 10
L785: interface ReminderRequestCalendar extends ReminderRequest {
  // @since 9 | @syscap SystemCapability.Notification.ReminderAgent
L792: dateTime: LocalDateTime;
  // @since 9 | @syscap SystemCapability.Notification.ReminderAgent | @since 12 | @since 11
L833: interface ReminderRequestAlarm extends ReminderRequest {
  // @since 9 | @syscap SystemCapability.Notification.ReminderAgent
L840: hour: number;
  // @since 9 | @syscap SystemCapability.Notification.ReminderAgent
L847: minute: number;
  // @since 9 | @syscap SystemCapability.Notification.ReminderAgent
L865: interface ReminderRequestTimer extends ReminderRequest {
  // @since 9 | @syscap SystemCapability.Notification.ReminderAgent
L874: triggerTimeInSeconds: number;
  // @since 12 | @syscap SystemCapability.Notification.ReminderAgent | @since 26.0.0 | @stagemodelonly | @since 9
L899: interface ReminderInfo {
  // @since 12 | @syscap SystemCapability.Notification.ReminderAgent
L906: reminderId: number;
  // @since 12 | @syscap SystemCapability.Notification.ReminderAgent
L913: reminderReq: ReminderRequest;
  // @since 9 | @syscap SystemCapability.Notification.ReminderAgent | @since 12
L921: interface LocalDateTime {
  // @since 9 | @syscap SystemCapability.Notification.ReminderAgent
L928: year: number;
  // @since 9 | @syscap SystemCapability.Notification.ReminderAgent
L935: month: number;
  // @since 9 | @syscap SystemCapability.Notification.ReminderAgent
L942: day: number;
  // @since 9 | @syscap SystemCapability.Notification.ReminderAgent
L949: hour: number;
  // @since 9 | @syscap SystemCapability.Notification.ReminderAgent
L956: minute: number;
  // @since 23 | @stagemodelonly | @syscap SystemCapability.Notification.ReminderAgent | @since 9
L982: interface ReminderState {
  // @since 23 | @stagemodelonly | @syscap SystemCapability.Notification.ReminderAgent
L991: reminderId: number;
  // @since 23 | @stagemodelonly | @syscap SystemCapability.Notification.ReminderAgent
L999: buttonType: ActionButtonType;
  // @since 23 | @stagemodelonly | @syscap SystemCapability.Notification.ReminderAgent
L1013: isMessageResent: boolean;
```

### `openharmony/ets/api/@ohos.net.http.d.ts`

用途：HTTP 请求
大小：150 KB（含类/接口成员）

```ts
  // @since 11 | @atomicservice | @syscap SystemCapability.Communication.NetStack | @since 10 | @since 6
L43: declare namespace http {
  // @since 12 | @atomicservice | @syscap SystemCapability.Communication.NetStack | @since 11 | @since 10
L63: type HttpProxy = connection.HttpProxy;
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.Communication.NetStack
L71: type Socks5Proxy = connection.Socks5Proxy;
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.Communication.NetStack
L86: export type QueryParamValue = string | number | boolean | null | undefined;
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.Communication.NetStack
L122: export type QueryParamObject = Record<string, QueryParamValue | QueryParamValue[]>;
  // @since 11 | @atomicservice | @syscap SystemCapability.Communication.NetStack | @since 10 | @since 6
L144: function createHttp(): HttpRequest;
  // @since 15 | @syscap SystemCapability.Communication.NetStack
L151: export enum AddressFamily {
  // @since 11 | @atomicservice | @syscap SystemCapability.Communication.NetStack | @since 10 | @since 6 | @since 15
L192: export interface HttpRequestOptions {
  // @since 18 | @atomicservice | @syscap SystemCapability.Communication.NetStack | @since 26.0.0 | @stagemodelonly | @since 23 | @since 15
L752: export interface ServerAuthentication {
  // @since 18 | @atomicservice | @syscap SystemCapability.Communication.NetStack
L760: credential: Credential;
  // @since 18 | @atomicservice | @syscap SystemCapability.Communication.NetStack
L779: export type TlsOptions = 'system' | TlsConfig;
  // @since 18 | @atomicservice | @syscap SystemCapability.Communication.NetStack
L789: export type RemoteValidation = 'system' | 'skip' | ValidationCallback;
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.Communication.NetStack
L797: export type X509Cert = cert.X509Cert;
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.Communication.NetStack
L805: export interface ValidationContext {
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.Communication.NetStack
L813: pemCerts: string[];
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.Communication.NetStack
L821: x509Certs: X509Cert[];
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.Communication.NetStack
L829: host: string;
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.Communication.NetStack
L837: ip: string;
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.Communication.NetStack
L850: export type ValidationCallback = (context: ValidationContext) => boolean | Promise<boolean>;
  // @since 18 | @atomicservice | @syscap SystemCapability.Communication.NetStack
L858: export type AuthenticationType = 'basic' | 'ntlm' | 'digest';
  // @since 20 | @atomicservice | @syscap SystemCapability.Communication.NetStack
L866: export type SslType = 'TLS' | 'TLCP';
  // @since 23 | @syscap SystemCapability.Communication.NetStack
L875: export type PathPreference = 'auto' | 'primaryCellular' | 'secondaryCellular';
  // @since 18 | @atomicservice | @syscap SystemCapability.Communication.NetStack
L883: export interface Credential {
  // @since 18 | @atomicservice | @syscap SystemCapability.Communication.NetStack
L891: username: string;
  // @since 18 | @atomicservice | @syscap SystemCapability.Communication.NetStack
L899: password: string;
  // @since 18 | @atomicservice | @syscap SystemCapability.Communication.NetStack
L908: export interface TlsConfig {
  // @since 18 | @atomicservice | @syscap SystemCapability.Communication.NetStack
L916: tlsVersionMin: TlsVersion;
  // @since 18 | @atomicservice | @syscap SystemCapability.Communication.NetStack
L924: tlsVersionMax: TlsVersion;
  // @since 18 | @atomicservice | @syscap SystemCapability.Communication.NetStack
L942: export type TlsV13SpecificCipherSuite = 'TLS_AES_128_GCM_SHA256' | 'TLS_AES_256_GCM_SHA384' | 'TLS_CHACHA20_POLY1305_SHA256';
  // @since 18 | @atomicservice | @syscap SystemCapability.Communication.NetStack
L950: export type TlsV12SpecificCipherSuite = 'TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256' | 'TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256' | 'TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384' | 'TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384' | 'TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305_SHA256' | 'TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305_SHA256' | 'TLS_RSA_WITH_AES_128_GCM_SHA256' | 'TLS_RSA_WITH_AES_256_GCM_SHA384';
  // @since 18 | @atomicservice | @syscap SystemCapability.Communication.NetStack
L958: export type TlsV10SpecificCipherSuite = 'TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA' | 'TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA' | 'TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA' | 'TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA' | 'TLS_RSA_WITH_AES_128_CBC_SHA' | 'TLS_RSA_WITH_AES_256_CBC_SHA' | 'TLS_RSA_WITH_3DES_EDE_CBC_SHA';
  // @since 18 | @atomicservice | @syscap SystemCapability.Communication.NetStack
L966: export type CipherSuite = TlsV13CipherSuite;
  // @since 18 | @atomicservice | @syscap SystemCapability.Communication.NetStack
L974: export type TlsV13CipherSuite = TlsV12CipherSuite | TlsV13SpecificCipherSuite;
  // @since 18 | @atomicservice | @syscap SystemCapability.Communication.NetStack
L982: export type TlsV12CipherSuite = TlsV11CipherSuite | TlsV12SpecificCipherSuite;
  // @since 18 | @atomicservice | @syscap SystemCapability.Communication.NetStack
L990: export type TlsV11CipherSuite = TlsV10CipherSuite;
  // @since 18 | @atomicservice | @syscap SystemCapability.Communication.NetStack
L998: export type TlsV10CipherSuite = TlsV10SpecificCipherSuite;
  // @since 18 | @atomicservice | @syscap SystemCapability.Communication.NetStack
L1006: export enum TlsVersion {
  // @since 12 | @syscap SystemCapability.Communication.NetStack | @since 11 | @since 18 | @atomicservice
L1049: export interface MultiFormData {
  // @since 12 | @syscap SystemCapability.Communication.NetStack | @since 11
L1063: name: string;
  // @since 12 | @syscap SystemCapability.Communication.NetStack | @since 11
L1077: contentType: string;
  // @since 12 | @syscap SystemCapability.Communication.NetStack | @since 11
L1140: export enum CertType {
  // @since 12 | @syscap SystemCapability.Communication.NetStack | @since 11
L1193: export interface ClientCert {
  // @since 12 | @syscap SystemCapability.Communication.NetStack | @since 11
L1207: certPath: string;
  // @since 12 | @syscap SystemCapability.Communication.NetStack | @since 11
L1235: keyPath: string;
  // @since 12 | @syscap SystemCapability.Communication.NetStack | @since 11
L1257: interface CertificatePinning {
  // @since 12 | @syscap SystemCapability.Communication.NetStack
L1264: publicKeyHash: string;
  // @since 12 | @syscap SystemCapability.Communication.NetStack
L1271: hashAlgorithm: 'SHA-256';
  // @since 11 | @atomicservice | @syscap SystemCapability.Communication.NetStack | @since 10 | @since 6 | @since 12
L1297: export interface HttpRequest {
  // @since 6 | @atomicservice [since 11] | @syscap SystemCapability.Communication.NetStack | @permission ohos.permission.INTERNET
L1358: request(url: string, callback: AsyncCallback<HttpResponse>): void;
  // @since 6 | @atomicservice [since 11] | @syscap SystemCapability.Communication.NetStack | @permission ohos.permission.INTERNET
L1424: request(url: string, options: HttpRequestOptions, callback: AsyncCallback<HttpResponse>): void;
  // @since 6 | @atomicservice [since 11] | @syscap SystemCapability.Communication.NetStack | @permission ohos.permission.INTERNET
L1488: request(url: string, options?: HttpRequestOptions): Promise<HttpResponse>;
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.Communication.NetStack | @permission ohos.permission.INTERNET | @since 6 | @atomicservice [since 11]
L1550: requestSync(url: string, options?: HttpRequestOptions): HttpResponse;
  // @since 10 | @atomicservice [since 15] | @syscap SystemCapability.Communication.NetStack | @permission ohos.permission.INTERNET | @since 26.0.0 | @stagemodelonly
L1599: requestInStream(url: string, callback: AsyncCallback<number>): void;
  // @since 10 | @atomicservice [since 15] | @syscap SystemCapability.Communication.NetStack | @permission ohos.permission.INTERNET
L1651: requestInStream(url: string, options: HttpRequestOptions, callback: AsyncCallback<number>): void;
  // @since 10 | @atomicservice [since 15] | @syscap SystemCapability.Communication.NetStack | @permission ohos.permission.INTERNET
L1701: requestInStream(url: string, options?: HttpRequestOptions): Promise<number>;
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.Communication.NetStack | @since 10 | @atomicservice [since 15] | @permission ohos.permission.INTERNET
L1710: enableAutoCookie(enable: boolean): void;
  // @since 11 | @atomicservice | @syscap SystemCapability.Communication.NetStack | @since 10 | @since 6 | @since 26.0.0 | @stagemodelonly | @atomicservice [since 15]
L1729: destroy(): void;
  // @deprecated since 8 | @since 6 | @syscap SystemCapability.Communication.NetStack | @since 11 | @atomicservice | @since 10 | @since 26.0.0 | @stagemodelonly | @atomicservice [since 15]
L1739: on(type: "headerReceive", callback: AsyncCallback<Object>): void;
  // @deprecated since 8 | @since 6 | @syscap SystemCapability.Communication.NetStack | @since 11 | @atomicservice | @since 10 | @since 26.0.0 | @stagemodelonly | @atomicservice [since 15]
L1749: off(type: "headerReceive", callback?: AsyncCallback<Object>): void;
  // @since 11 | @atomicservice | @syscap SystemCapability.Communication.NetStack | @since 10 | @since 8 | @deprecated since 8 | @since 6 | @since 26.0.0 | @stagemodelonly
L1774: on(type: "headersReceive", callback: Callback<Object>): void;
  // @since 11 | @atomicservice | @syscap SystemCapability.Communication.NetStack | @since 10 | @since 8 | @deprecated since 8 | @since 6
L1799: off(type: "headersReceive", callback?: Callback<Object>): void;
  // @since 15 | @atomicservice | @syscap SystemCapability.Communication.NetStack | @since 10 | @since 8 | @since 11
L1824: once(type: "headersReceive", callback: Callback<Object>): void;
  // @since 18 | @atomicservice | @syscap SystemCapability.Communication.NetStack | @since 15 | @since 10 | @since 8 | @since 11
L1849: on(type: "dataReceive", callback: Callback<ArrayBuffer>): void;
  // @since 18 | @atomicservice | @syscap SystemCapability.Communication.NetStack | @since 15 | @since 10 | @since 8
L1874: off(type: "dataReceive", callback?: Callback<ArrayBuffer>): void;
  // @since 18 | @atomicservice | @syscap SystemCapability.Communication.NetStack | @since 15 | @since 10
L1899: on(type: "dataEnd", callback: Callback<void>): void;
  // @since 18 | @atomicservice | @syscap SystemCapability.Communication.NetStack | @since 15 | @since 10
L1924: off(type: "dataEnd", callback?: Callback<void>): void;
  // @since 15 | @atomicservice | @syscap SystemCapability.Communication.NetStack | @since 12 | @since 11 | @since 10 | @since 18
L1956: on(type: 'dataReceiveProgress', callback: Callback<DataReceiveProgressInfo>): void;
  // @since 15 | @atomicservice | @syscap SystemCapability.Communication.NetStack | @since 12 | @since 11 | @since 10 | @since 18
L1988: off(type: 'dataReceiveProgress', callback?: Callback<DataReceiveProgressInfo>): void;
  // @since 15 | @atomicservice | @syscap SystemCapability.Communication.NetStack | @since 12 | @since 11 | @since 10
L2013: on(type: 'dataSendProgress', callback: Callback<DataSendProgressInfo>): void;
  // @since 15 | @atomicservice | @syscap SystemCapability.Communication.NetStack | @since 12 | @since 11
L2038: off(type: 'dataSendProgress', callback?: Callback<DataSendProgressInfo>): void;
  // @since 11 | @atomicservice | @syscap SystemCapability.Communication.NetStack | @since 10 | @since 6 | @since 15 | @since 12
L2061: export enum RequestMethod {
  // @since 11 | @atomicservice | @syscap SystemCapability.Communication.NetStack | @since 10 | @since 6 | @since 26.0.0 | @stagemodelonly
L2245: export enum ResponseCode {
  // @since 11 | @atomicservice | @syscap SystemCapability.Communication.NetStack | @since 10 | @since 9 | @since 6
L2947: export enum HttpProtocol {
  // @since 11 | @atomicservice | @syscap SystemCapability.Communication.NetStack | @since 10 | @since 9 | @since 12
L3024: export enum HttpDataType {
  // @since 11 | @atomicservice | @syscap SystemCapability.Communication.NetStack | @since 10 | @since 6 | @since 9
L3104: export interface HttpResponse {
  // @since 11 | @atomicservice | @syscap SystemCapability.Communication.NetStack | @since 10 | @since 6
L3129: result: string | Object | ArrayBuffer;
  // @since 11 | @atomicservice | @syscap SystemCapability.Communication.NetStack | @since 10 | @since 9 | @since 6
L3157: resultType: HttpDataType;
  // @since 11 | @atomicservice | @syscap SystemCapability.Communication.NetStack | @since 10 | @since 6 | @since 9
L3179: responseCode: ResponseCode | number;
  // @since 11 | @atomicservice | @syscap SystemCapability.Communication.NetStack | @since 10 | @since 6 | @since 9
L3201: header: Object;
  // @since 11 | @atomicservice | @syscap SystemCapability.Communication.NetStack | @since 10 | @since 8 | @since 6
L3223: cookies: string;
  // @since 12 | @syscap SystemCapability.Communication.NetStack | @since 11 | @atomicservice | @since 10 | @since 8 | @since 6
L3237: performanceTiming: PerformanceTiming;
  // @since 12 | @syscap SystemCapability.Communication.NetStack | @since 11 | @since 24 | @atomicservice | @since 10 | @since 8
L3260: export interface PerformanceTiming {
  // @since 12 | @syscap SystemCapability.Communication.NetStack | @since 11
L3274: dnsTiming: number;
  // @since 12 | @syscap SystemCapability.Communication.NetStack | @since 11
L3288: tcpTiming: number;
  // @since 12 | @syscap SystemCapability.Communication.NetStack | @since 11
L3302: tlsTiming: number;
  // @since 12 | @syscap SystemCapability.Communication.NetStack | @since 11
L3316: firstSendTiming: number;
  // @since 12 | @syscap SystemCapability.Communication.NetStack | @since 11
L3330: firstReceiveTiming: number;
  // @since 12 | @syscap SystemCapability.Communication.NetStack | @since 11
L3344: totalFinishTiming: number;
  // @since 12 | @syscap SystemCapability.Communication.NetStack | @since 11
L3358: redirectTiming: number;
  // @since 12 | @syscap SystemCapability.Communication.NetStack | @since 11
L3372: responseHeaderTiming: number;
  // @since 12 | @syscap SystemCapability.Communication.NetStack | @since 11
L3386: responseBodyTiming: number;
  // @since 12 | @syscap SystemCapability.Communication.NetStack | @since 11
L3400: totalTiming: number;
  // @since 15 | @atomicservice | @syscap SystemCapability.Communication.NetStack | @since 12 | @since 11
L3423: export interface DataReceiveProgressInfo {
  // @since 15 | @atomicservice | @syscap SystemCapability.Communication.NetStack | @since 12 | @since 11
L3445: receiveSize: number;
  // @since 15 | @atomicservice | @syscap SystemCapability.Communication.NetStack | @since 12 | @since 11
L3467: totalSize: number;
  // @since 15 | @atomicservice | @syscap SystemCapability.Communication.NetStack | @since 12 | @since 11
L3490: export interface DataSendProgressInfo {
  // @since 15 | @atomicservice | @syscap SystemCapability.Communication.NetStack | @since 12 | @since 11
L3512: sendSize: number;
  // @since 15 | @atomicservice | @syscap SystemCapability.Communication.NetStack | @since 12 | @since 11
L3534: totalSize: number;
  // @since 11 | @atomicservice | @syscap SystemCapability.Communication.NetStack | @since 10 | @since 9 | @since 15 | @since 12
L3560: function createHttpResponseCache(cacheSize?: number): HttpResponseCache;
  // @since 11 | @atomicservice | @syscap SystemCapability.Communication.NetStack | @since 10 | @since 9
L3582: export interface HttpResponseCache {
  // @since 11 | @atomicservice | @syscap SystemCapability.Communication.NetStack | @since 10 | @since 9
L3604: flush(callback: AsyncCallback<void>): void;
  // @since 11 | @atomicservice | @syscap SystemCapability.Communication.NetStack | @since 10 | @since 9
L3626: flush(): Promise<void>;
  // @since 11 | @atomicservice | @syscap SystemCapability.Communication.NetStack | @since 10 | @since 9
L3648: delete(callback: AsyncCallback<void>): void;
  // @since 11 | @atomicservice | @syscap SystemCapability.Communication.NetStack | @since 10 | @since 9
L3670: delete(): Promise<void>;
  // @since 22 | @atomicservice | @syscap SystemCapability.Communication.NetStack | @since 11 | @since 10 | @since 9
L3679: export enum InterceptorType {
  // @since 22 | @atomicservice | @syscap SystemCapability.Communication.NetStack
L3723: export interface HttpRequestContext {
  // @since 22 | @atomicservice | @syscap SystemCapability.Communication.NetStack
L3731: url: string;
  // @since 22 | @atomicservice | @syscap SystemCapability.Communication.NetStack
L3739: header: Object;
  // @since 22 | @atomicservice | @syscap SystemCapability.Communication.NetStack
L3747: body: Object;
  // @since 22 | @atomicservice | @syscap SystemCapability.Communication.NetStack
L3756: export type ChainContinue = boolean;
  // @since 22 | @atomicservice | @syscap SystemCapability.Communication.NetStack
L3764: export interface HttpInterceptor {
  // @since 22 | @atomicservice | @syscap SystemCapability.Communication.NetStack
L3772: interceptorType: InterceptorType;
  // @since 22 | @atomicservice | @syscap SystemCapability.Communication.NetStack
L3782: interceptorHandle(reqContext: HttpRequestContext, rspContext: HttpResponse): Promise<ChainContinue>;
  // @since 22 | @atomicservice | @syscap SystemCapability.Communication.NetStack
L3791: export class HttpInterceptorChain {
  // @since 24 | @stagemodelonly | @syscap SystemCapability.Communication.NetStack | @since 22 | @atomicservice
L3833: export interface ConnectionExtraInfo {
  // @since 24 | @stagemodelonly | @syscap SystemCapability.Communication.NetStack
L3841: networkProtocolName: string;
  // @since 24 | @stagemodelonly | @syscap SystemCapability.Communication.NetStack
L3865: localAddress: string;
  // @since 24 | @stagemodelonly | @syscap SystemCapability.Communication.NetStack
L3873: remoteAddress: string;
  // @since 24 | @stagemodelonly | @syscap SystemCapability.Communication.NetStack
L3881: localPort: number;
  // @since 24 | @stagemodelonly | @syscap SystemCapability.Communication.NetStack
L3889: remotePort: number;
  // @since 24 | @stagemodelonly | @syscap SystemCapability.Communication.NetStack
L3897: isReusedConnection: boolean;
  // @since 24 | @stagemodelonly | @syscap SystemCapability.Communication.NetStack
L3905: isProxyConnection: boolean;
  // @since 24 | @stagemodelonly | @syscap SystemCapability.Communication.NetStack
L3913: isCacheHit: boolean;
  // @since 24 | @stagemodelonly | @syscap SystemCapability.Communication.NetStack
L3921: redirectCount: number;
```

### `openharmony/ets/api/@ohos.net.connection.d.ts`

用途：网络状态监听
大小：111 KB（含类/接口成员）

```ts
  // @since 11 | @atomicservice | @syscap SystemCapability.Communication.NetManager.Core | @since 10 | @since 8
L43: declare namespace connection {
  // @since 11 | @atomicservice | @syscap SystemCapability.Communication.NetStack | @since 10 | @since 8
L63: type HttpRequest = http.HttpRequest;
  // @since 10 | @syscap SystemCapability.Communication.NetStack | @since 8
L76: type TCPSocket = socket.TCPSocket;
  // @since 10 | @syscap SystemCapability.Communication.NetStack | @since 8
L89: type UDPSocket = socket.UDPSocket;
  // @since 11 | @atomicservice | @syscap SystemCapability.Communication.NetManager.Core | @since 10 | @since 8
L120: function createNetConnection(netSpecifier?: NetSpecifier, timeout?: number): NetConnection;
  // @since 11 | @atomicservice | @syscap SystemCapability.Communication.NetManager.Core | @permission ohos.permission.GET_NETWORK_INFO | @since 8
L146: function getDefaultNet(callback: AsyncCallback<NetHandle>): void;
  // @since 11 | @atomicservice | @syscap SystemCapability.Communication.NetManager.Core | @permission ohos.permission.GET_NETWORK_INFO | @since 8
L171: function getDefaultNet(): Promise<NetHandle>;
  // @since 11 | @atomicservice | @syscap SystemCapability.Communication.NetManager.Core | @permission ohos.permission.GET_NETWORK_INFO | @since 9
L196: function getDefaultNetSync(): NetHandle;
  // @since 8 | @syscap SystemCapability.Communication.NetManager.Core | @permission ohos.permission.GET_NETWORK_INFO
L209: function getAllNets(callback: AsyncCallback<Array<NetHandle>>): void;
  // @since 8 | @syscap SystemCapability.Communication.NetManager.Core | @permission ohos.permission.GET_NETWORK_INFO
L221: function getAllNets(): Promise<Array<NetHandle>>;
  // @since 10 | @syscap SystemCapability.Communication.NetManager.Core | @permission ohos.permission.GET_NETWORK_INFO
L233: function getAllNetsSync(): Array<NetHandle>;
  // @since 8 | @syscap SystemCapability.Communication.NetManager.Core | @permission ohos.permission.GET_NETWORK_INFO
L248: function getConnectionProperties(netHandle: NetHandle, callback: AsyncCallback<ConnectionProperties>): void;
  // @since 8 | @syscap SystemCapability.Communication.NetManager.Core | @permission ohos.permission.GET_NETWORK_INFO
L263: function getConnectionProperties(netHandle: NetHandle): Promise<ConnectionProperties>;
  // @since 10 | @syscap SystemCapability.Communication.NetManager.Core | @permission ohos.permission.GET_NETWORK_INFO
L278: function getConnectionPropertiesSync(netHandle: NetHandle): ConnectionProperties;
  // @since 11 | @atomicservice | @syscap SystemCapability.Communication.NetManager.Core | @permission ohos.permission.GET_NETWORK_INFO | @since 8
L308: function getNetCapabilities(netHandle: NetHandle, callback: AsyncCallback<NetCapabilities>): void;
  // @since 11 | @atomicservice | @syscap SystemCapability.Communication.NetManager.Core | @permission ohos.permission.GET_NETWORK_INFO | @since 8
L338: function getNetCapabilities(netHandle: NetHandle): Promise<NetCapabilities>;
  // @since 11 | @atomicservice | @syscap SystemCapability.Communication.NetManager.Core | @permission ohos.permission.GET_NETWORK_INFO | @since 10
L368: function getNetCapabilitiesSync(netHandle: NetHandle): NetCapabilities;
  // @since 20 | @syscap SystemCapability.Communication.NetManager.Core | @permission ohos.permission.SET_NET_EXT_ATTRIBUTE
L383: function setNetExtAttribute(netHandle: NetHandle, netExtAttribute: string): Promise<void>;
  // @since 20 | @syscap SystemCapability.Communication.NetManager.Core | @permission ohos.permission.SET_NET_EXT_ATTRIBUTE
L397: function setNetExtAttributeSync(netHandle: NetHandle, netExtAttribute: string): void;
  // @since 20 | @syscap SystemCapability.Communication.NetManager.Core | @permission ohos.permission.GET_NETWORK_INFO
L411: function getNetExtAttribute(netHandle: NetHandle): Promise<string>;
  // @since 20 | @syscap SystemCapability.Communication.NetManager.Core | @permission ohos.permission.GET_NETWORK_INFO
L425: function getNetExtAttributeSync(netHandle: NetHandle): string;
  // @since 9 | @syscap SystemCapability.Communication.NetManager.Core | @permission ohos.permission.GET_NETWORK_INFO
L438: function isDefaultNetMetered(callback: AsyncCallback<boolean>): void;
  // @since 9 | @syscap SystemCapability.Communication.NetManager.Core | @permission ohos.permission.GET_NETWORK_INFO
L449: function isDefaultNetMetered(): Promise<boolean>;
  // @since 10 | @syscap SystemCapability.Communication.NetManager.Core | @permission ohos.permission.GET_NETWORK_INFO
L460: function isDefaultNetMeteredSync(): boolean;
  // @since 10 | @syscap SystemCapability.Communication.NetManager.Core | @permission ohos.permission.GET_NETWORK_INFO | @since 8
L486: function hasDefaultNet(callback: AsyncCallback<boolean>): void;
  // @since 10 | @syscap SystemCapability.Communication.NetManager.Core | @permission ohos.permission.GET_NETWORK_INFO | @since 8
L509: function hasDefaultNet(): Promise<boolean>;
  // @since 10 | @syscap SystemCapability.Communication.NetManager.Core | @permission ohos.permission.GET_NETWORK_INFO
L520: function hasDefaultNetSync(): boolean;
  // @since 8 | @syscap SystemCapability.Communication.NetManager.Core | @permission ohos.permission.GET_NETWORK_INFO and ohos.permission.INTERNET
L534: function reportNetConnected(netHandle: NetHandle, callback: AsyncCallback<void>): void;
  // @since 8 | @syscap SystemCapability.Communication.NetManager.Core | @permission ohos.permission.GET_NETWORK_INFO and ohos.permission.INTERNET
L548: function reportNetConnected(netHandle: NetHandle): Promise<void>;
  // @since 8 | @syscap SystemCapability.Communication.NetManager.Core | @permission ohos.permission.GET_NETWORK_INFO and ohos.permission.INTERNET
L562: function reportNetDisconnected(netHandle: NetHandle, callback: AsyncCallback<void>): void;
  // @since 8 | @syscap SystemCapability.Communication.NetManager.Core | @permission ohos.permission.GET_NETWORK_INFO and ohos.permission.INTERNET
L576: function reportNetDisconnected(netHandle: NetHandle): Promise<void>;
  // @since 8 | @syscap SystemCapability.Communication.NetManager.Core | @permission ohos.permission.INTERNET
L590: function getAddressesByName(host: string, callback: AsyncCallback<Array<NetAddress>>): void;
  // @since 8 | @syscap SystemCapability.Communication.NetManager.Core | @permission ohos.permission.INTERNET
L604: function getAddressesByName(host: string): Promise<Array<NetAddress>>;
  // @since 23 | @stagemodelonly | @syscap SystemCapability.Communication.NetManager.Core | @permission ohos.permission.INTERNET
L620: function getAddressesByNameWithOptions(host: string, option?: QueryOptions): Promise<Array<NetAddress>>;
  // @since 9 | @syscap SystemCapability.Communication.NetManager.Core
L631: function getAppNet(callback: AsyncCallback<NetHandle>): void;
  // @since 9 | @syscap SystemCapability.Communication.NetManager.Core
L640: function getAppNet(): Promise<NetHandle>;
  // @since 10 | @syscap SystemCapability.Communication.NetManager.Core
L649: function getAppNetSync(): NetHandle;
  // @since 9 | @syscap SystemCapability.Communication.NetManager.Core | @permission ohos.permission.INTERNET
L665: function setAppNet(netHandle: NetHandle, callback: AsyncCallback<void>): void;
  // @since 9 | @syscap SystemCapability.Communication.NetManager.Core | @permission ohos.permission.INTERNET
L681: function setAppNet(netHandle: NetHandle): Promise<void>;
  // @since 10 | @syscap SystemCapability.Communication.NetManager.Core
L696: function getDefaultHttpProxy(callback: AsyncCallback<HttpProxy>): void;
  // @since 10 | @syscap SystemCapability.Communication.NetManager.Core
L711: function getDefaultHttpProxy(): Promise<HttpProxy>;
  // @since 11 | @syscap SystemCapability.Communication.NetManager.Core
L720: function setAppHttpProxy(httpProxy: HttpProxy): void;
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.Communication.NetManager.Core | @permission ohos.permission.INTERNET
L734: function refreshGlobalHttpProxy(): Promise<HttpProxy>;
  // @since 15 | @syscap SystemCapability.Communication.NetManager.Core | @permission ohos.permission.SET_PAC_URL
L747: function setPacUrl(pacUrl: string): void;
  // @since 15 | @syscap SystemCapability.Communication.NetManager.Core
L756: function getPacUrl(): string;
  // @since 20 | @syscap SystemCapability.Communication.NetManager.Core | @permission ohos.permission.SET_PAC_URL
L768: function setPacFileUrl(pacFileUrl: string): void;
  // @since 20 | @syscap SystemCapability.Communication.NetManager.Core
L776: function getPacFileUrl(): string;
  // @since 20 | @syscap SystemCapability.Communication.NetManager.Core
L784: function findProxyForUrl(url: string): string;
  // @since 15 | @atomicservice | @syscap SystemCapability.Communication.NetManager.Core | @permission ohos.permission.INTERNET | @since 11
L814: function addCustomDnsRule(host: string, ip: Array<string>, callback: AsyncCallback<void>): void;
  // @since 15 | @atomicservice | @syscap SystemCapability.Communication.NetManager.Core | @permission ohos.permission.INTERNET | @since 11
L844: function addCustomDnsRule(host: string, ip: Array<string>): Promise<void>;
  // @since 15 | @atomicservice | @syscap SystemCapability.Communication.NetManager.Core | @permission ohos.permission.INTERNET | @since 11
L872: function removeCustomDnsRule(host: string, callback: AsyncCallback<void>): void;
  // @since 15 | @atomicservice | @syscap SystemCapability.Communication.NetManager.Core | @permission ohos.permission.INTERNET | @since 11
L900: function removeCustomDnsRule(host: string): Promise<void>;
  // @since 11 | @syscap SystemCapability.Communication.NetManager.Core | @permission ohos.permission.INTERNET
L913: function clearCustomDnsRules(callback: AsyncCallback<void>): void;
  // @since 11 | @syscap SystemCapability.Communication.NetManager.Core | @permission ohos.permission.INTERNET
L925: function clearCustomDnsRules(): Promise<void>;
  // @since 23 | @syscap SystemCapability.Communication.NetManager.Core | @permission ohos.permission.GET_NETWORK_INFO
L943: function getConnectOwnerUid(protocol: ProtocolType, local: NetAddress, remote: NetAddress): Promise<number>;
  // @since 23 | @stagemodelonly | @syscap SystemCapability.Communication.NetManager.Core | @permission ohos.permission.GET_NETWORK_INFO
L962: function getConnectOwnerUidSync(protocol: ProtocolType, local: NetAddress, remote: NetAddress): number;
  // @since 22 | @syscap SystemCapability.Communication.NetManager.Core | @permission ohos.permission.GET_NETWORK_INFO and ohos.permission.GET_IP_MAC_INFO
L973: function getIpNeighTable(): Promise<Array<NetIpMacInfo>>;
  // @since 23 | @syscap SystemCapability.Communication.NetManager.Core
L987: function getDnsAscii(host: string, flag?: ConversionProcess): string;
  // @since 23 | @syscap SystemCapability.Communication.NetManager.Core
L1001: function getDnsUnicode(host: string, flag?: ConversionProcess): string;
  // @since 24 | @stagemodelonly | @syscap SystemCapability.Communication.NetManager.Core | @permission ohos.permission.GET_IP_MAC_INFO
L1015: function getSystemNetPortStates(): Promise<NetPortStatesInfo>;
  // @since 24 | @stagemodelonly | @syscap SystemCapability.Communication.NetManager.Core
L1024: export interface NetPortStatesInfo {
  // @since 24 | @stagemodelonly | @syscap SystemCapability.Communication.NetManager.Core
L1052: export interface TcpNetPortStatesInfo {
  // @since 24 | @stagemodelonly | @syscap SystemCapability.Communication.NetManager.Core
L1061: tcpLocalIp: string;
  // @since 24 | @stagemodelonly | @syscap SystemCapability.Communication.NetManager.Core
L1070: tcpLocalPort: number;
  // @since 24 | @stagemodelonly | @syscap SystemCapability.Communication.NetManager.Core
L1079: tcpRemoteIp: string;
  // @since 24 | @stagemodelonly | @syscap SystemCapability.Communication.NetManager.Core
L1088: tcpRemotePort: number;
  // @since 24 | @stagemodelonly | @syscap SystemCapability.Communication.NetManager.Core
L1097: tcpUid: number;
  // @since 24 | @stagemodelonly | @syscap SystemCapability.Communication.NetManager.Core
L1106: tcpPid: number;
  // @since 24 | @stagemodelonly | @syscap SystemCapability.Communication.NetManager.Core
L1115: tcpState: TcpState;
  // @since 24 | @stagemodelonly | @syscap SystemCapability.Communication.NetManager.Core
L1125: export interface UdpNetPortStatesInfo {
  // @since 24 | @stagemodelonly | @syscap SystemCapability.Communication.NetManager.Core
L1134: udpLocalIp: string;
  // @since 24 | @stagemodelonly | @syscap SystemCapability.Communication.NetManager.Core
L1143: udpLocalPort: number;
  // @since 24 | @stagemodelonly | @syscap SystemCapability.Communication.NetManager.Core
L1152: udpUid: number;
  // @since 24 | @stagemodelonly | @syscap SystemCapability.Communication.NetManager.Core
L1161: udpPid: number;
  // @since 24 | @stagemodelonly | @syscap SystemCapability.Communication.NetManager.Core
L1171: export enum TcpState {
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.Communication.NetManager.Core | @permission ohos.permission.INTERNET and ohos.permission.ACCESS_NET_TRACE_INFO and | @since 24
L1276: function queryTraceRoute(destination: string, option?: TraceRouteOptions): Promise<TraceRouteInfo[]>;
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.Communication.NetManager.Core | @permission ohos.permission.INTERNET
L1291: function queryProbeResult(destination: string, duration: number): Promise<ProbeResultInfo>;
  // @since 11 | @atomicservice | @syscap SystemCapability.Communication.NetManager.Core | @since 10 | @since 8
L1313: export interface NetConnection {
  // @since 11 | @atomicservice | @syscap SystemCapability.Communication.NetManager.Core | @since 10 | @since 8
L1338: on(type: 'netAvailable', callback: Callback<NetHandle>): void;
  // @since 11 | @syscap SystemCapability.Communication.NetManager.Core | @since 8 | @atomicservice | @since 10
L1353: on(type: 'netBlockStatusChange', callback: Callback<NetBlockStatusInfo>): void;
  // @since 11 | @atomicservice | @syscap SystemCapability.Communication.NetManager.Core | @since 10 | @since 8
L1378: on(type: 'netCapabilitiesChange', callback: Callback<NetCapabilityInfo>): void;
  // @since 11 | @syscap SystemCapability.Communication.NetManager.Core | @since 8 | @atomicservice | @since 10
L1393: on(type: 'netConnectionPropertiesChange', callback: Callback<NetConnectionPropertyInfo>): void;
  // @since 11 | @atomicservice | @syscap SystemCapability.Communication.NetManager.Core | @since 10 | @since 8
L1418: on(type: 'netLost', callback: Callback<NetHandle>): void;
  // @since 11 | @atomicservice | @syscap SystemCapability.Communication.NetManager.Core | @since 10 | @since 8
L1443: on(type: 'netUnavailable', callback: Callback<void>): void;
  // @since 11 | @atomicservice | @syscap SystemCapability.Communication.NetManager.Core | @permission ohos.permission.GET_NETWORK_INFO | @since 10 | @since 8
L1486: register(callback: AsyncCallback<void>): void;
  // @since 12 | @atomicservice | @syscap SystemCapability.Communication.NetManager.Core | @since 11 | @since 10 | @since 8 | @permission ohos.permission.GET_NETWORK_INFO
L1535: unregister(callback: AsyncCallback<void>): void;
  // @since 11 | @atomicservice | @syscap SystemCapability.Communication.NetManager.Core | @since 8 | @since 12 | @since 10
L1550: export interface NetSpecifier {
  // @since 11 | @atomicservice | @syscap SystemCapability.Communication.NetManager.Core | @since 8
L1564: netCapabilities: NetCapabilities;
  // @since 23 | @syscap SystemCapability.Communication.NetManager.Core | @since 11 | @atomicservice | @since 8
L1586: export interface QueryOptions {
  // @since 23 | @syscap SystemCapability.Communication.NetManager.Core
L1601: export enum FamilyType {
  // @since 11 | @atomicservice | @syscap SystemCapability.Communication.NetManager.Core | @since 10 | @since 23
L1636: export interface NetCapabilityInfo {
  // @since 11 | @atomicservice | @syscap SystemCapability.Communication.NetManager.Core | @since 10
L1652: netHandle: NetHandle;
  // @since 11 | @atomicservice | @syscap SystemCapability.Communication.NetManager.Core | @since 10
L1668: netCap: NetCapabilities;
  // @since 11 | @atomicservice | @syscap SystemCapability.Communication.NetManager.Core | @since 10 | @since 8
L1691: export interface NetHandle {
  // @since 11 | @atomicservice | @syscap SystemCapability.Communication.NetManager.Core | @since 10 | @since 8
L1713: netId: number;
  // @since 9 | @syscap SystemCapability.Communication.NetManager.Core | @since 11 | @atomicservice | @since 10 | @since 8
L1727: bindSocket(socketParam: TCPSocket | UDPSocket, callback: AsyncCallback<void>): void;
  // @since 9 | @syscap SystemCapability.Communication.NetManager.Core | @since 11 | @atomicservice | @since 10 | @since 8
L1741: bindSocket(socketParam: TCPSocket | UDPSocket): Promise<void>;
  // @since 15 | @atomicservice | @syscap SystemCapability.Communication.NetManager.Core | @permission ohos.permission.INTERNET | @since 8 | @since 9 | @since 11 | @since 10
L1769: getAddressesByName(host: string, callback: AsyncCallback<Array<NetAddress>>): void;
  // @since 15 | @atomicservice | @syscap SystemCapability.Communication.NetManager.Core | @permission ohos.permission.INTERNET | @since 8 | @since 9
L1797: getAddressesByName(host: string): Promise<Array<NetAddress>>;
  // @since 23 | @stagemodelonly | @syscap SystemCapability.Communication.NetManager.Core | @permission ohos.permission.INTERNET | @since 15 | @atomicservice | @since 8
L1813: getAddressesByNameWithOptions(host: string, option?: QueryOptions): Promise<Array<NetAddress>>;
  // @since 8 | @syscap SystemCapability.Communication.NetManager.Core | @permission ohos.permission.INTERNET | @since 23 | @stagemodelonly | @since 15 | @atomicservice
L1827: getAddressByName(host: string, callback: AsyncCallback<NetAddress>): void;
  // @since 8 | @syscap SystemCapability.Communication.NetManager.Core | @permission ohos.permission.INTERNET | @since 23 | @stagemodelonly | @since 15 | @atomicservice
L1841: getAddressByName(host: string): Promise<NetAddress>;
  // @since 11 | @atomicservice | @syscap SystemCapability.Communication.NetManager.Core | @since 10 | @since 8 | @permission ohos.permission.INTERNET | @since 23 | @stagemodelonly | @since 15
L1864: export interface NetCapabilities {
  // @since 11 | @atomicservice | @syscap SystemCapability.Communication.NetManager.Core | @since 10 | @since 8
L1914: bearerTypes: Array<NetBearType>;
  // @since 11 | @syscap SystemCapability.Communication.NetManager.Core | @atomicservice | @since 10 | @since 8
L1922: export interface NetConnectionPropertyInfo {
  // @since 11 | @syscap SystemCapability.Communication.NetManager.Core
L1929: netHandle: NetHandle;
  // @since 11 | @syscap SystemCapability.Communication.NetManager.Core
L1936: connectionProperties: ConnectionProperties;
  // @since 11 | @syscap SystemCapability.Communication.NetManager.Core
L1944: export interface NetBlockStatusInfo {
  // @since 11 | @syscap SystemCapability.Communication.NetManager.Core
L1951: netHandle: NetHandle;
  // @since 11 | @syscap SystemCapability.Communication.NetManager.Core
L1958: blocked: boolean;
  // @since 11 | @atomicservice | @syscap SystemCapability.Communication.NetManager.Core | @since 8
L1973: export enum NetCap {
  // @since 11 | @atomicservice | @syscap SystemCapability.Communication.NetManager.Core | @since 10 | @since 8 | @since 12
L2070: export enum NetBearType {
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.Communication.NetManager.Core | @since 12 | @since 11 | @atomicservice | @since 8 | @since 10
L2143: export enum Socks5DnsStrategy {
  // @since 23 | @syscap SystemCapability.Communication.NetManager.Core | @since 26.0.0 | @stagemodelonly
L2167: export enum ConversionProcess {
  // @since 8 | @syscap SystemCapability.Communication.NetManager.Core | @since 23
L2193: export interface ConnectionProperties {
  // @since 8 | @syscap SystemCapability.Communication.NetManager.Core
L2200: interfaceName: string;
  // @since 8 | @syscap SystemCapability.Communication.NetManager.Core
L2207: domains: string;
  // @since 8 | @syscap SystemCapability.Communication.NetManager.Core
L2214: linkAddresses: Array<LinkAddress>;
  // @since 8 | @syscap SystemCapability.Communication.NetManager.Core
L2221: dnses: Array<NetAddress>;
  // @since 8 | @syscap SystemCapability.Communication.NetManager.Core
L2228: routes: Array<RouteInfo>;
  // @since 8 | @syscap SystemCapability.Communication.NetManager.Core
L2235: mtu: number;
  // @since 8 | @syscap SystemCapability.Communication.NetManager.Core | @since 24 | @stagemodelonly
L2261: export interface RouteInfo {
  // @since 8 | @syscap SystemCapability.Communication.NetManager.Core
L2268: interface: string;
  // @since 8 | @syscap SystemCapability.Communication.NetManager.Core
L2275: destination: LinkAddress;
  // @since 8 | @syscap SystemCapability.Communication.NetManager.Core
L2282: gateway: NetAddress;
  // @since 8 | @syscap SystemCapability.Communication.NetManager.Core
L2289: hasGateway: boolean;
  // @since 8 | @syscap SystemCapability.Communication.NetManager.Core
L2296: isDefaultRoute: boolean;
  // @since 8 | @syscap SystemCapability.Communication.NetManager.Core | @since 20
L2311: export interface LinkAddress {
  // @since 8 | @syscap SystemCapability.Communication.NetManager.Core
L2318: address: NetAddress;
  // @since 8 | @syscap SystemCapability.Communication.NetManager.Core
L2325: prefixLength: number;
  // @since 24 | @atomicservice | @syscap SystemCapability.Communication.NetManager.Core | @since 12 | @since 8
L2348: export interface NetAddress {
  // @since 24 | @atomicservice | @syscap SystemCapability.Communication.NetManager.Core | @since 12 | @since 8
L2370: address: string;
  // @since 24 | @atomicservice | @syscap SystemCapability.Communication.NetManager.Core | @since 11 | @since 10 | @since 12 | @since 8
L2437: export interface HttpProxy {
  // @since 24 | @atomicservice | @syscap SystemCapability.Communication.NetManager.Core | @since 11 | @since 10
L2459: host: string;
  // @since 24 | @atomicservice | @syscap SystemCapability.Communication.NetManager.Core | @since 11 | @since 10
L2481: port: number;
  // @since 11 | @atomicservice | @syscap SystemCapability.Communication.NetManager.Core | @since 10 | @since 12 | @since 24
L2509: exclusionList: Array<string>;
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.Communication.NetManager.Core | @since 11 | @atomicservice | @since 10 | @since 12 | @since 24
L2518: export interface Socks5Proxy {
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.Communication.NetManager.Core
L2526: host: string;
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.Communication.NetManager.Core
L2534: port: number;
  // @since 22 | @syscap SystemCapability.Communication.NetManager.Core | @since 26.0.0 | @stagemodelonly
L2575: export interface NetIpMacInfo {
  // @since 22 | @syscap SystemCapability.Communication.NetManager.Core
L2582: ipAddress: NetAddress;
  // @since 22 | @syscap SystemCapability.Communication.NetManager.Core
L2589: macAddress: string;
  // @since 22 | @syscap SystemCapability.Communication.NetManager.Core
L2596: iface: string;
  // @since 23 | @syscap SystemCapability.Communication.NetManager.Core | @since 22
L2604: export enum ProtocolType {
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.Communication.NetManager.Core | @since 23
L2625: export enum PacketsType {
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.Communication.NetManager.Core
L2650: export interface TraceRouteOptions {
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.Communication.NetManager.Core
L2675: export interface TraceRouteInfo {
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.Communication.NetManager.Core
L2683: jumpNo: number;
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.Communication.NetManager.Core
L2691: address: string;
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.Communication.NetManager.Core
L2699: rtt: number[];
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.Communication.NetManager.Core
L2708: export interface ProbeResultInfo {
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.Communication.NetManager.Core
L2716: lossRate: number;
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.Communication.NetManager.Core
L2724: rtt: number[];
```

### `openharmony/ets/api/@ohos.arkui.UIContext.d.ts`

用途：UIContext 与 PromptAction
大小：263 KB（超过 200 KB，只出顶层声明、不摘 JSDoc 与类成员）

```ts
L53: export class Font {
L110: export class MediaQuery {
L132: export class UIInspector {
L176: export class Router {
L671: declare type CustomBuilderWithId = (id: number) => void;
L681: export interface TargetInfo {
L725: export class PromptAction {
L1233: declare type ClickEventListenerCallback = (event: ClickEvent, node?: FrameNode) => void;
L1246: declare type PanListenerCallback = (event: GestureEvent, current: GestureRecognizer, node?: FrameNode) => void;
L1258: declare type GestureEventListenerCallback = (event: GestureEvent, node?: FrameNode) => void;
L1272: export declare type NodeIdentity = string | number;
L1285: export declare type NodeRenderStateChangeCallback = (state: NodeRenderState, node?: FrameNode) => void;
L1296: export declare type GestureListenerCallback = (info: GestureTriggerInfo) => void;
L1311: export interface PageInfo {
L1344: export interface OverlayManagerOptions {
L1382: export interface OrderOverlayOptions {
L1438: export class UIObserver {
L2393: export interface SwiperContentInfo {
L2438: export interface SwiperItemInfo {
L2478: export class ComponentUtils {
L2525: export class OverlayManager {
L2654: export class Magnifier {
L2712: export interface AtomicServiceBar {
L2796: export interface GestureTriggerInfo {
L2850: export interface GestureObserverConfigs {
L2870: export class DynamicSyncScene {
L2907: export class SwiperDynamicSyncScene extends DynamicSyncScene {
L2927: export class MarqueeDynamicSyncScene extends DynamicSyncScene {
L2954: export class DragController {
L3133: export class MeasureUtils {
L3199: export class FocusController {
L3290: export type PointerStyle = pointer.PointerStyle;
L3307: export class CursorController {
L3369: export declare class ContextMenuController {
L3436: export type Context = common.Context;
L3458: export class ComponentSnapshot {
L3821: export class ClickActionProposal extends TargetedGestureProposal {
L3844: export class SelectActionProposal extends TargetedGestureProposal {
L3867: export class NoneActionProposal extends BaseGestureHandlingProposal {
L3889: export class BackPressActionProposal extends BaseGestureHandlingProposal {
L3912: export class PageSwitchActionProposal extends TargetedGestureProposal {
L3951: export class ScrollActionProposal extends TargetedGestureProposal {
L3986: export class GestureHandlingResolution {
L4043: export class SmartGestureController {
L4155: export const enum ResolveStrategy {
L4233: export class ResolvedUIContext extends UIContext {
L4267: export class UIContext {
L5605: export const enum KeyboardAvoidMode {
L5661: export const enum TextSelectionClearPolicy {
L5692: export const enum SwiperDynamicSyncSceneType {
L5721: export const enum MarqueeDynamicSyncSceneType {
L5747: export class TextMenuController {
L5874: export const enum NodeRenderState {
L5914: export const enum GestureActionPhase {
L5947: export const enum GestureListenerType {
L6019: export const enum CustomKeyboardContinueFeature {
```

### `openharmony/ets/api/@ohos.arkui.uiMaterial.d.ts`

用途：★鸿蒙7 系统材质（ImmersiveMaterial / ImmersiveStyle / MaterialState）
大小：19 KB（含类/接口成员）

```ts
  // @since 26.0.0 | @atomicservice | @form | @stagemodelonly | @syscap SystemCapability.ArkUI.ArkUI.Full
L32: declare namespace uiMaterial {
  // @since 26.0.0 | @atomicservice | @form | @stagemodelonly | @syscap SystemCapability.ArkUI.ArkUI.Full
L43: enum MaterialType {
  // @since 26.0.0 | @atomicservice | @stagemodelonly | @syscap SystemCapability.ArkUI.ArkUI.Full
L68: enum MaterialState {
  // @since 26.0.0 | @atomicservice | @stagemodelonly | @syscap SystemCapability.ArkUI.ArkUI.Full
L125: interface MaterialInfo {
  // @since 26.0.0 | @atomicservice | @stagemodelonly | @syscap SystemCapability.ArkUI.ArkUI.Full
L136: state: MaterialState;
  // @since 26.0.0 | @atomicservice | @stagemodelonly | @syscap SystemCapability.ArkUI.ArkUI.Full
L148: type: MaterialType;
  // @since 26.0.0 | @atomicservice | @stagemodelonly | @syscap SystemCapability.ArkUI.ArkUI.Full
L163: function getMaterialInfo(): MaterialInfo;
  // @since 26.0.0 | @atomicservice | @stagemodelonly | @syscap SystemCapability.ArkUI.ArkUI.Full
L174: enum ImmersiveStyle {
  // @since 26.0.0 | @atomicservice | @stagemodelonly | @syscap SystemCapability.ArkUI.ArkUI.Full
L235: interface ImmersiveOptions {
  // @since 26.0.0 | @atomicservice | @stagemodelonly | @syscap SystemCapability.ArkUI.ArkUI.Full
L369: interface LightEffectOptions {
  // @since 26.0.0 | @atomicservice | @form | @stagemodelonly | @syscap SystemCapability.ArkUI.ArkUI.Full
L394: class Material {
  // @since 26.0.0 | @atomicservice | @stagemodelonly | @syscap SystemCapability.ArkUI.ArkUI.Full
L410: static get empty(): Material;
  // @since 26.0.0 | @atomicservice | @stagemodelonly | @syscap SystemCapability.ArkUI.ArkUI.Full
L432: class ImmersiveMaterial extends Material {
  // @since 26.0.0 | @atomicservice | @stagemodelonly | @syscap SystemCapability.ArkUI.ArkUI.Full
L446: constructor(options?: ImmersiveOptions);
```

### `openharmony/ets/api/@ohos.arkui.StateManagement.d.ts`

用途：★状态管理 V2 全局存储（AppStorageV2 / PersistenceV2）
大小：54 KB（含类/接口成员）

```ts
  // @since 12 | @atomicservice | @stagemodelonly | @syscap SystemCapability.ArkUI.ArkUI.Full
L41: export declare type StorageDefaultCreator<T> = () => T;
  // @since 12 | @atomicservice | @stagemodelonly | @syscap SystemCapability.ArkUI.ArkUI.Full
L51: export interface TypeConstructorWithArgs<T> {
  // @since 12 | @atomicservice | @stagemodelonly | @syscap SystemCapability.ArkUI.ArkUI.Full
L63: new (...args: any): T;
  // @since 18 | @atomicservice | @stagemodelonly | @syscap SystemCapability.ArkUI.ArkUI.Full | @since 12
L73: export class ConnectOptions<T extends object> {
  // @since 18 | @atomicservice | @stagemodelonly | @syscap SystemCapability.ArkUI.ArkUI.Full
L82: type: TypeConstructorWithArgs<T>;
  // @since 12 | @atomicservice | @stagemodelonly | @syscap SystemCapability.ArkUI.ArkUI.Full | @since 18
L125: export declare class AppStorageV2 {
  // @since 12 | @atomicservice | @stagemodelonly | @syscap SystemCapability.ArkUI.ArkUI.Full
L144: static connect<T extends object>(type: TypeConstructorWithArgs<T>, keyOrDefaultCreator?: string | StorageDefaultCreator<T>, defaultCreator?: StorageDefaultCreator<T>): T | undefined;
  // @since 12 | @atomicservice | @stagemodelonly | @syscap SystemCapability.ArkUI.ArkUI.Full
L157: static remove<T>(keyOrType: string | TypeConstructorWithArgs<T>): void;
  // @since 12 | @atomicservice | @stagemodelonly | @syscap SystemCapability.ArkUI.ArkUI.Full
L168: static keys(): Array<string>;
  // @since 12 | @atomicservice | @stagemodelonly | @syscap SystemCapability.ArkUI.ArkUI.Full
L183: export declare type PersistenceErrorCallback = (key: string, reason: 'quota' | 'serialization' | 'unknown', message: string, oldValue?: string) => void;
  // @since 23 | @atomicservice | @stagemodelonly | @syscap SystemCapability.ArkUI.ArkUI.Full
L199: export declare type CollectionType<S> = Array<S> | Map<string | number, S> | Set<S> | collections.Array<S> | collections.Map<string | number, S> | collections.Set<S>;
  // @since 23 | @atomicservice | @stagemodelonly | @syscap SystemCapability.ArkUI.ArkUI.Full
L213: export class ConnectOptionsCollections<T extends CollectionType<S>, S extends object> extends ConnectOptions<T> {
  // @since 12 | @atomicservice | @stagemodelonly | @syscap SystemCapability.ArkUI.ArkUI.Full | @since 23
L247: export declare class PersistenceV2 extends AppStorageV2 {
  // @since 18 | @atomicservice | @stagemodelonly | @syscap SystemCapability.ArkUI.ArkUI.Full
L265: static globalConnect<T extends object>(type: ConnectOptions<T>): T | undefined;
  // @since 23 | @atomicservice | @stagemodelonly | @syscap SystemCapability.ArkUI.ArkUI.Full | @since 18
L285: static globalConnect<T extends CollectionType<S>, S extends object>(type: ConnectOptionsCollections<T, S> | ConnectOptions<T>): T | undefined;
  // @since 12 | @atomicservice | @stagemodelonly | @syscap SystemCapability.ArkUI.ArkUI.Full | @since 23 | @since 18
L297: static save<T>(keyOrType: string | TypeConstructorWithArgs<T>): void;
  // @since 12 | @atomicservice | @stagemodelonly | @syscap SystemCapability.ArkUI.ArkUI.Full | @since 23 | @since 18
L308: static notifyOnError(callback: PersistenceErrorCallback | undefined): void;
  // @since 12 | @atomicservice | @stagemodelonly | @syscap SystemCapability.ArkUI.ArkUI.Full | @since 23 | @since 18
L319: export interface TypeConstructor<T> {
  // @since 12 | @atomicservice | @stagemodelonly | @syscap SystemCapability.ArkUI.ArkUI.Full
L330: new (): T;
  // @since 12 | @atomicservice | @stagemodelonly | @syscap SystemCapability.ArkUI.ArkUI.Full
L343: export declare type TypeDecorator = <T>(type: TypeConstructor<T>) => PropertyDecorator;
  // @since 12 | @atomicservice | @stagemodelonly | @syscap SystemCapability.ArkUI.ArkUI.Full
L353: export declare const Type: TypeDecorator;
  // @since 12 | @atomicservice | @stagemodelonly | @syscap SystemCapability.ArkUI.ArkUI.Full
L363: export declare class UIUtils {
  // @since 12 | @atomicservice | @stagemodelonly | @syscap SystemCapability.ArkUI.ArkUI.Full
L376: static getTarget<T extends object>(source: T): T;
  // @since 12 | @atomicservice | @stagemodelonly | @syscap SystemCapability.ArkUI.ArkUI.Full
L394: static makeObserved<T extends object>(source: T): T;
  // @since 19 | @atomicservice | @stagemodelonly | @syscap SystemCapability.ArkUI.ArkUI.Full | @since 12
L416: static makeV1Observed<T extends object>(source: T): T;
  // @since 19 | @atomicservice | @stagemodelonly | @syscap SystemCapability.ArkUI.ArkUI.Full | @since 12
L431: static enableV2Compatibility<T extends object>(source: T): T;
  // @since 20 | @atomicservice | @stagemodelonly | @syscap SystemCapability.ArkUI.ArkUI.Full | @since 19 | @since 12
L457: static addMonitor(target: object, path: string | string[], monitorCallback: MonitorCallback, options?: MonitorOptions): void;
  // @since 20 | @atomicservice | @stagemodelonly | @syscap SystemCapability.ArkUI.ArkUI.Full | @since 19
L483: static clearMonitor(target: object, path: string | string[], monitorCallback?: MonitorCallback): void;
  // @since 20 | @atomicservice | @stagemodelonly | @syscap SystemCapability.ArkUI.ArkUI.Full | @since 19
L498: static makeBinding<T>(getter: GetterCallback<T>): Binding<T>;
  // @since 20 | @atomicservice | @stagemodelonly | @syscap SystemCapability.ArkUI.ArkUI.Full
L516: static makeBinding<T>(getter: GetterCallback<T>, setter: SetterCallback<T>): MutableBinding<T>;
  // @since 22 | @atomicservice | @stagemodelonly | @syscap SystemCapability.ArkUI.ArkUI.Full | @since 20
L534: static applySync<T>(task: TaskCallback): T;
  // @since 22 | @atomicservice | @stagemodelonly | @syscap SystemCapability.ArkUI.ArkUI.Full | @since 20
L548: static flushUpdates(): void;
  // @since 22 | @atomicservice | @stagemodelonly | @syscap SystemCapability.ArkUI.ArkUI.Full | @since 20
L563: static flushUIUpdates(): void;
  // @since 23 | @atomicservice | @stagemodelonly | @syscap SystemCapability.ArkUI.ArkUI.Full | @since 22 | @since 20
L578: static canBeObserved<T extends object>(source: T): ObservedResult;
  // @since 23 | @atomicservice | @stagemodelonly | @syscap SystemCapability.ArkUI.ArkUI.Full | @since 22
L590: static getLifecycle<T extends BaseCustomComponent>(customComponent: T): CustomComponentLifecycle;
  // @since 26.0.0 | @atomicservice | @stagemodelonly | @syscap SystemCapability.ArkUI.ArkUI.Full | @since 23 | @since 22
L605: static getCustomComponentContext<T extends BaseCustomComponent>(customComponent: T): CustomComponentContext;
  // @since 22 | @atomicservice | @stagemodelonly | @syscap SystemCapability.ArkUI.ArkUI.Full | @since 26.0.0 | @since 23
L617: declare type TaskCallback = () => T;
  // @since 20 | @atomicservice | @stagemodelonly | @syscap SystemCapability.ArkUI.ArkUI.Full
L628: export declare type MonitorCallback = (monitorValue: IMonitor) => void;
  // @since 20 | @atomicservice | @stagemodelonly | @syscap SystemCapability.ArkUI.ArkUI.Full
L639: export interface MonitorOptions {
  // @since 20 | @atomicservice | @stagemodelonly | @syscap SystemCapability.ArkUI.ArkUI.Full | @since 26.0.0
L676: export declare type GetterCallback<T> = () => T;
  // @since 20 | @atomicservice | @stagemodelonly | @syscap SystemCapability.ArkUI.ArkUI.Full
L687: export declare type SetterCallback<T> = (newValue: T) => void;
  // @since 20 | @atomicservice | @stagemodelonly | @syscap SystemCapability.ArkUI.ArkUI.Full
L697: export declare class Binding<T> {
  // @since 20 | @atomicservice | @stagemodelonly | @syscap SystemCapability.ArkUI.ArkUI.Full
L709: get value(): T;
  // @since 20 | @atomicservice | @stagemodelonly | @syscap SystemCapability.ArkUI.ArkUI.Full
L721: export declare class MutableBinding<T> {
  // @since 20 | @atomicservice | @stagemodelonly | @syscap SystemCapability.ArkUI.ArkUI.Full
L733: get value(): T;
  // @since 20 | @atomicservice | @stagemodelonly | @syscap SystemCapability.ArkUI.ArkUI.Full
L747: set value(newValue: T);
  // @since 23 | @atomicservice | @stagemodelonly | @syscap SystemCapability.ArkUI.ArkUI.Full | @since 20
L758: export interface ObservedResult {
  // @since 23 | @atomicservice | @stagemodelonly | @syscap SystemCapability.ArkUI.ArkUI.Full
L772: isObserved: boolean;
  // @since 23 | @atomicservice | @stagemodelonly | @syscap SystemCapability.ArkUI.ArkUI.Full
L805: reason: string;
  // @since 23 | @atomicservice | @stagemodelonly | @syscap SystemCapability.ArkUI.ArkUI.Full
L816: decoratorInfo: Array<DecoratorInfo>;
  // @since 23 | @atomicservice | @stagemodelonly | @syscap SystemCapability.ArkUI.ArkUI.Full
L827: export interface DecoratorInfo {
  // @since 23 | @atomicservice | @stagemodelonly | @syscap SystemCapability.ArkUI.ArkUI.Full
L851: decoratorName: string;
  // @since 23 | @atomicservice | @stagemodelonly | @syscap SystemCapability.ArkUI.ArkUI.Full
L861: stateVariableName: string;
  // @since 23 | @atomicservice | @stagemodelonly | @syscap SystemCapability.ArkUI.ArkUI.Full
L878: owningComponentOrClassName: string;
  // @since 23 | @atomicservice | @stagemodelonly | @syscap SystemCapability.ArkUI.ArkUI.Full
L893: owningComponentId: number;
  // @since 23 | @atomicservice | @stagemodelonly | @syscap SystemCapability.ArkUI.ArkUI.Full
L904: dependentInfo: Array<ElementInfo>;
  // @since 23 | @atomicservice | @stagemodelonly | @syscap SystemCapability.ArkUI.ArkUI.Full
L916: export interface ElementInfo {
  // @since 23 | @atomicservice | @stagemodelonly | @syscap SystemCapability.ArkUI.ArkUI.Full
L926: elementName: string;
  // @since 23 | @atomicservice | @stagemodelonly | @syscap SystemCapability.ArkUI.ArkUI.Full
L936: elementId: number;
  // @since 23 | @atomicservice | @stagemodelonly | @syscap SystemCapability.ArkUI.ArkUI.Full
L947: export declare interface CustomComponentLifecycle {
  // @since 23 | @atomicservice | @stagemodelonly | @syscap SystemCapability.ArkUI.ArkUI.Full
L958: getCurrentState(): CustomComponentLifecycleState;
  // @since 23 | @atomicservice | @stagemodelonly | @syscap SystemCapability.ArkUI.ArkUI.Full
L969: addObserver(observer: CustomComponentLifecycleObserver): void;
  // @since 23 | @atomicservice | @stagemodelonly | @syscap SystemCapability.ArkUI.ArkUI.Full
L981: removeObserver(observer: CustomComponentLifecycleObserver): void;
  // @since 23 | @atomicservice | @stagemodelonly | @syscap SystemCapability.ArkUI.ArkUI.Full
L993: export declare interface CustomComponentLifecycleObserver {
  // @since 23 | @atomicservice | @stagemodelonly | @syscap SystemCapability.ArkUI.ArkUI.Full
L1068: export declare enum CustomComponentLifecycleState {
  // @since 23 | @atomicservice | @stagemodelonly | @syscap SystemCapability.ArkUI.ArkUI.Full
L1130: export declare const ComponentInit: MethodDecorator;
  // @since 23 | @atomicservice | @stagemodelonly | @syscap SystemCapability.ArkUI.ArkUI.Full
L1144: export declare const ComponentAppear: MethodDecorator;
  // @since 23 | @atomicservice | @stagemodelonly | @syscap SystemCapability.ArkUI.ArkUI.Full
L1157: export declare const ComponentBuilt: MethodDecorator;
  // @since 23 | @atomicservice | @stagemodelonly | @syscap SystemCapability.ArkUI.ArkUI.Full
L1177: export declare const ComponentReuse: MethodDecorator;
  // @since 23 | @atomicservice | @stagemodelonly | @syscap SystemCapability.ArkUI.ArkUI.Full
L1191: export declare const ComponentRecycle: MethodDecorator;
  // @since 26.0.0 | @atomicservice | @stagemodelonly | @syscap SystemCapability.ArkUI.ArkUI.Full
L1201: export declare const ComponentActive: MethodDecorator;
  // @since 26.0.0 | @atomicservice | @stagemodelonly | @syscap SystemCapability.ArkUI.ArkUI.Full
L1211: export declare const ComponentInactive: MethodDecorator;
  // @since 23 | @atomicservice | @stagemodelonly | @syscap SystemCapability.ArkUI.ArkUI.Full
L1223: export declare const ComponentDisappear: MethodDecorator;
  // @since 26.0.0 | @atomicservice | @stagemodelonly | @syscap SystemCapability.ArkUI.ArkUI.Full
L1234: export declare interface CustomComponentContext {
  // @since 26.0.0 | @atomicservice | @stagemodelonly | @syscap SystemCapability.ArkUI.ArkUI.Full
L1249: getReusePool(): IReusePool | undefined;
  // @since 26.0.0 | @atomicservice | @stagemodelonly | @syscap SystemCapability.ArkUI.ArkUI.Full
L1260: export declare interface IReusePool {
  // @since 26.0.0 | @atomicservice | @stagemodelonly | @syscap SystemCapability.ArkUI.ArkUI.Full
L1283: getReusableInfo(constructor: ReusableComponentConstructor, reuseId?: string): IReusableInfo[] | IReusableInfo | undefined;
  // @since 26.0.0 | @atomicservice | @stagemodelonly | @syscap SystemCapability.ArkUI.ArkUI.Full
L1298: preRender(builder: WrappedBuilder<[ ]>, times: number): Promise<void>;
  // @since 26.0.0 | @atomicservice | @stagemodelonly | @syscap SystemCapability.ArkUI.ArkUI.Full
L1311: export declare interface IReusableInfo {
  // @since 26.0.0 | @atomicservice | @stagemodelonly | @syscap SystemCapability.ArkUI.ArkUI.Full
L1323: readonly count: number;
  // @since 26.0.0 | @atomicservice | @stagemodelonly | @syscap SystemCapability.ArkUI.ArkUI.Full
L1336: maxCount: number;
  // @since 26.0.0 | @atomicservice | @stagemodelonly | @syscap SystemCapability.ArkUI.ArkUI.Full
L1357: declare type ReusableComponentConstructor = Function;
```

### `openharmony/ets/api/@ohos.arkui.components.ContainerReader.d.ts`

用途：★鸿蒙7 容器断点 ContainerReader
大小：6 KB（含类/接口成员）

```ts
  // @since 26.0.0 | @atomicservice | @form | @stagemodelonly | @syscap SystemCapability.ArkUI.ArkUI.Full
L31: export interface ContainerReaderInfo {
  // @since 26.0.0 | @atomicservice | @form | @stagemodelonly | @syscap SystemCapability.ArkUI.ArkUI.Full
L43: size: Size;
  // @since 26.0.0 | @atomicservice | @form | @stagemodelonly | @syscap SystemCapability.ArkUI.ArkUI.Full
L80: export interface BreakpointOptions {
  // @since 26.0.0 | @atomicservice | @form | @stagemodelonly | @syscap SystemCapability.ArkUI.ArkUI.Full
L118: export interface ContainerReaderInterface {
  // @since 26.0.0 | @atomicservice | @form | @stagemodelonly | @syscap SystemCapability.ArkUI.ArkUI.Full
L145: export declare class ContainerReaderAttribute extends CommonMethod<ContainerReaderAttribute> {
  // @since 26.0.0 | @atomicservice | @form | @stagemodelonly | @syscap SystemCapability.ArkUI.ArkUI.Full
L159: breakpointConfig(value?: BreakpointOptions): ContainerReaderAttribute;
  // @since 26.0.0 | @atomicservice | @form | @stagemodelonly | @syscap SystemCapability.ArkUI.ArkUI.Full
L173: export declare const ContainerReader: ContainerReaderInterface;
  // @since 26.0.0 | @atomicservice | @form | @stagemodelonly | @syscap SystemCapability.ArkUI.ArkUI.Full
L186: export declare const ContainerReaderInstance: ContainerReaderAttribute;
```

### `openharmony/ets/api/@ohos.arkui.components.ArkLazyWaterFlowLayout.d.ts`

用途：★鸿蒙7 懒加载瀑布流 LazyVWaterFlowLayout
大小：6 KB（含类/接口成员）

```ts
  // @since 26.0.0 | @atomicservice | @stagemodelonly | @syscap SystemCapability.ArkUI.ArkUI.Full
L29: export interface LazyVWaterFlowLayoutInterface {
  // @since 26.0.0 | @atomicservice | @stagemodelonly | @syscap SystemCapability.ArkUI.ArkUI.Full
L52: export declare class LazyWaterFlowLayoutAttribute<T> extends CommonMethod<T> {
  // @since 26.0.0 | @atomicservice | @stagemodelonly | @syscap SystemCapability.ArkUI.ArkUI.Full
L65: rowsGap(value: LengthMetrics | undefined): T;
  // @since 26.0.0 | @atomicservice | @stagemodelonly | @syscap SystemCapability.ArkUI.ArkUI.Full
L78: columnsGap(value: LengthMetrics | undefined): T;
  // @since 26.0.0 | @atomicservice | @stagemodelonly | @syscap SystemCapability.ArkUI.ArkUI.Full
L91: header(builder: CustomBuilder | undefined): T;
  // @since 26.0.0 | @atomicservice | @stagemodelonly | @syscap SystemCapability.ArkUI.ArkUI.Full
L104: footer(builder: CustomBuilder | undefined): T;
  // @since 26.0.0 | @atomicservice | @stagemodelonly | @syscap SystemCapability.ArkUI.ArkUI.Full
L116: sticky(sticky: StickyStyle | undefined): T;
  // @since 26.0.0 | @atomicservice | @stagemodelonly | @syscap SystemCapability.ArkUI.ArkUI.Full
L131: onVisibleIndexesChange(callback: OnVisibleIndexesChangeCallback | undefined): T;
  // @since 26.0.0 | @atomicservice | @stagemodelonly | @syscap SystemCapability.ArkUI.ArkUI.Full
L143: export declare class LazyVWaterFlowLayoutAttribute extends LazyWaterFlowLayoutAttribute<LazyVWaterFlowLayoutAttribute> {
  // @since 26.0.0 | @atomicservice | @stagemodelonly | @syscap SystemCapability.ArkUI.ArkUI.Full
L161: columnsTemplate(value: string | ItemFillPolicy | undefined): LazyVWaterFlowLayoutAttribute;
  // @since 26.0.0 | @atomicservice | @stagemodelonly | @syscap SystemCapability.ArkUI.ArkUI.Full
L174: export declare const LazyVWaterFlowLayout: LazyVWaterFlowLayoutInterface;
  // @since 26.0.0 | @atomicservice | @stagemodelonly | @syscap SystemCapability.ArkUI.ArkUI.Full
L185: export declare const LazyVWaterFlowLayoutInstance: LazyVWaterFlowLayoutAttribute;
```

### `openharmony/ets/api/@ohos.window.floatView.d.ts`

用途：★鸿蒙7 闪控窗 floatView
大小：40 KB（含类/接口成员）

```ts
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.Window.SessionManager
L74: declare namespace floatView {
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.Window.SessionManager
L87: function isFloatViewEnabled(): boolean;
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.Window.SessionManager
L105: function create(config: FloatViewConfiguration): Promise<FloatViewController>;
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.Window.SessionManager | @permission ohos.permission.USE_FLOAT_BALL and ohos.permission.FLOAT_VIEW
L150: function bind(floatViewController: FloatViewController, floatingBallController: floatingBall.FloatingBallController, floatingBallParams: floatingBall.FloatingBallParams): Promise<void>;
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.Window.SessionManager
L173: function unbind(floatViewController: FloatViewController, floatingBallController: floatingBall.FloatingBallController): Promise<void>;
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.Window.SessionManager
L190: function getFloatViewLimits(templateType: FloatViewTemplateType): FloatViewLimits;
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.Window.SessionManager
L198: interface FloatViewConfiguration {
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.Window.SessionManager
L206: context: BaseContext;
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.Window.SessionManager
L214: templateType: FloatViewTemplateType;
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.Window.SessionManager
L234: interface TemplateProperty {
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.Window.SessionManager
L242: templateType: FloatViewTemplateType;
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.Window.SessionManager
L250: size: window.Size;
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.Window.SessionManager
L262: interface FloatViewController {
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.Window.SessionManager
L280: setUIContext(path: string, storage?: LocalStorage): Promise<void>;
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.Window.SessionManager
L294: setUIContextByName(name: string, storage?: LocalStorage): Promise<void>;
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.Window.SessionManager
L316: setWindowSize(size: window.Size): Promise<void>;
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.Window.SessionManager
L339: switchTemplate(templateProperty: TemplateProperty): Promise<void>;
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.Window.SessionManager | @permission ohos.permission.FLOAT_VIEW
L369: start(): Promise<void>;
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.Window.SessionManager | @permission ohos.permission.FLOAT_VIEW
L390: stop(): Promise<void>;
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.Window.SessionManager | @permission ohos.permission.FLOAT_VIEW
L409: setFloatViewVisibilityInApp(isVisible: boolean): Promise<void>;
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.Window.SessionManager
L437: restoreMainWindow(wantParameters?: Record<string, Object>): Promise<void>;
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.Window.SessionManager
L450: getWindowProperties(): FloatViewProperties;
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.Window.SessionManager
L465: onStateChange(callback: Callback<FloatViewStateChangeInfo>): void;
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.Window.SessionManager
L478: offStateChange(callback?: Callback<FloatViewStateChangeInfo>): void;
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.Window.SessionManager
L493: onRectChange(callback: Callback<FloatViewRectChangeInfo>): void;
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.Window.SessionManager
L507: offRectChange(callback?: Callback<FloatViewRectChangeInfo>): void;
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.Window.SessionManager
L523: onLimitsChange(callback: Callback<FloatViewLimits>): void;
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.Window.SessionManager
L536: offLimitsChange(callback?: Callback<FloatViewLimits>): void;
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.Window.SessionManager
L545: enum FloatViewTemplateType {
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.Window.SessionManager
L570: interface FloatViewProperties {
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.Window.SessionManager
L578: templateType: FloatViewTemplateType;
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.Window.SessionManager
L586: windowId: number;
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.Window.SessionManager
L594: displayId: number;
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.Window.SessionManager
L602: windowRect: window.Rect;
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.Window.SessionManager
L610: windowScale: number;
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.Window.SessionManager
L624: avoidArea: window.AvoidArea;
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.Window.SessionManager
L632: inSidebar: boolean;
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.Window.SessionManager
L642: interface RatioLimit {
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.Window.SessionManager
L650: minRatio: number;
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.Window.SessionManager
L658: maxRatio: number;
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.Window.SessionManager
L667: interface FloatViewLimits {
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.Window.SessionManager
L675: minSize: window.Size;
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.Window.SessionManager
L683: maxSize: window.Size;
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.Window.SessionManager
L691: ratioLimits: Array<RatioLimit>;
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.Window.SessionManager
L700: interface FloatViewStateChangeInfo {
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.Window.SessionManager
L708: state: FloatViewState;
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.Window.SessionManager
L733: stopReason: string;
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.Window.SessionManager
L742: enum FloatViewState {
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.Window.SessionManager
L801: interface FloatViewRectChangeInfo {
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.Window.SessionManager
L809: windowRect: window.Rect;
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.Window.SessionManager
L817: windowScale: number;
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.Window.SessionManager
L831: reason: string;
```

### `openharmony/ets/api/@ohos.util.d.ts`

用途：工具类（base64 等）
大小：116 KB（含类/接口成员）

```ts
  // @since 7 | @atomicservice [since 11] | @syscap SystemCapability.Utils.Lang
L33: declare namespace util {
  // @deprecated since 9 | @since 7 | @syscap SystemCapability.Utils.Lang
L46: function printf(format: string, ...args: Object[]): string;
  // @since 9 | @atomicservice [since 12] | @syscap SystemCapability.Utils.Lang
L60: function format(format: string, ...args: Object[]): string;
  // @deprecated since 9 | @since 7 | @syscap SystemCapability.Utils.Lang
L71: function getErrorString(errno: number): string;
  // @since 9 | @atomicservice [since 12] | @syscap SystemCapability.Utils.Lang
L82: function errnoToString(errno: number): string;
  // @since 7 | @atomicservice [since 12] | @syscap SystemCapability.Utils.Lang
L110: function callbackWrapper(original: Function): (err: Object, value: Object) => void;
  // @since 9 | @atomicservice [since 12] | @syscap SystemCapability.Utils.Lang
L125: function promisify(original: (err: Object, value: Object) => void): Function;
  // @deprecated since 9 | @since 7 | @syscap SystemCapability.Utils.Lang
L138: function promiseWrapper(original: (err: Object, value: Object) => void): Object;
  // @since 9 | @atomicservice [since 12] | @syscap SystemCapability.Utils.Lang
L154: function generateRandomUUID(entropyCache?: boolean): string;
  // @since 9 | @atomicservice [since 12] | @syscap SystemCapability.Utils.Lang
L167: function generateRandomBinaryUUID(entropyCache?: boolean): Uint8Array;
  // @since 9 | @atomicservice [since 12] | @syscap SystemCapability.Utils.Lang
L181: function parseUUID(uuid: string): Uint8Array;
  // @since 12 | @atomicservice | @syscap SystemCapability.Utils.Lang
L195: function getHash(object: object): number;
  // @since 11 | @atomicservice | @syscap SystemCapability.Utils.Lang
L204: interface TextDecoderOptions {
  // @since 11 | @atomicservice | @syscap SystemCapability.Utils.Lang
L234: interface DecodeWithStreamOptions {
  // @since 12 | @atomicservice | @syscap SystemCapability.Utils.Lang | @since 11
L255: interface DecodeToStringOptions {
  // @since 7 | @atomicservice [since 11] | @syscap SystemCapability.Utils.Lang | @since 12 | @atomicservice
L278: class TextDecoder {
  // @since 9 | @atomicservice [since 12] | @syscap SystemCapability.Utils.Lang
L287: constructor();
  // @since 7 | @atomicservice [since 12] | @syscap SystemCapability.Utils.Lang | @since 9
L300: readonly encoding: string;
  // @since 7 | @atomicservice [since 12] | @syscap SystemCapability.Utils.Lang | @since 9
L310: readonly fatal: boolean;
  // @deprecated since 9 | @since 7 | @syscap SystemCapability.Utils.Lang | @atomicservice [since 12] | @since 9
L331: constructor(encoding?: string, options?: {
  // @since 9 | @atomicservice [since 11] | @syscap SystemCapability.Utils.Lang | @deprecated since 9 | @since 7 | @atomicservice [since 12]
L349: static create(encoding?: string, options?: TextDecoderOptions): TextDecoder;
  // @deprecated since 9 | @since 7 | @syscap SystemCapability.Utils.Lang | @since 9 | @atomicservice [since 11] | @atomicservice [since 12]
L361: decode(input: Uint8Array, options?: {
  // @deprecated since 12 | @since 9 | @atomicservice [since 11] | @syscap SystemCapability.Utils.Lang | @deprecated since 9 | @since 7 | @atomicservice [since 12]
L378: decodeWithStream(input: Uint8Array, options?: DecodeWithStreamOptions): string;
  // @since 12 | @atomicservice | @syscap SystemCapability.Utils.Lang | @deprecated since 12 | @since 9 | @atomicservice [since 11] | @deprecated since 9 | @since 7
L390: decodeToString(input: Uint8Array, options?: DecodeToStringOptions): string;
  // @since 11 | @atomicservice | @syscap SystemCapability.Utils.Lang | @since 12 | @deprecated since 12 | @since 9 | @atomicservice [since 11] | @deprecated since 9 | @since 7
L400: interface EncodeIntoUint8ArrayInfo {
  // @since 11 | @atomicservice | @syscap SystemCapability.Utils.Lang
L409: read: number;
  // @since 11 | @atomicservice | @syscap SystemCapability.Utils.Lang
L418: written: number;
  // @since 7 | @atomicservice [since 11] | @syscap SystemCapability.Utils.Lang | @since 11 | @atomicservice
L430: class TextEncoder {
  // @since 7 | @atomicservice [since 11] | @syscap SystemCapability.Utils.Lang | @atomicservice [since 12]
L452: constructor();
  // @since 9 | @atomicservice [since 11] | @syscap SystemCapability.Utils.Lang | @since 7 | @atomicservice [since 12]
L462: constructor(encoding?: string);
  // @since 12 | @atomicservice | @syscap SystemCapability.Utils.Lang | @since 9 | @atomicservice [since 11] | @since 7 | @atomicservice [since 12]
L473: static create(encoding?: string): TextEncoder;
  // @deprecated since 9 | @since 7 | @syscap SystemCapability.Utils.Lang | @since 12 | @atomicservice | @since 9 | @atomicservice [since 11] | @atomicservice [since 12]
L484: encode(input?: string): Uint8Array;
  // @since 9 | @atomicservice [since 11] | @syscap SystemCapability.Utils.Lang | @deprecated since 9 | @since 7 | @since 12 | @atomicservice | @atomicservice [since 12]
L496: encodeInto(input?: string): Uint8Array;
  // @deprecated since 9 | @since 7 | @syscap SystemCapability.Utils.Lang | @since 9 | @atomicservice [since 11] | @since 12 | @atomicservice | @atomicservice [since 12]
L509: encodeInto(input: string, dest: Uint8Array): {
  // @deprecated since 9 | @since 7 | @syscap SystemCapability.Utils.Lang | @since 9 | @atomicservice [since 11] | @since 12 | @atomicservice | @atomicservice [since 12]
L510: read: number;
  // @deprecated since 9 | @since 7 | @syscap SystemCapability.Utils.Lang | @since 9 | @atomicservice [since 11] | @since 12 | @atomicservice
L511: written: number;
  // @since 9 | @atomicservice [since 11] | @syscap SystemCapability.Utils.Lang | @deprecated since 9 | @since 7 | @since 12 | @atomicservice
L528: encodeIntoUint8Array(input: string, dest: Uint8Array): EncodeIntoUint8ArrayInfo;
  // @since 8 | @atomicservice [since 12] | @syscap SystemCapability.Utils.Lang | @since 9 | @atomicservice [since 11] | @deprecated since 9 | @since 7 | @since 12 | @atomicservice
L539: class RationalNumber {
  // @deprecated since 9 | @since 8 | @syscap SystemCapability.Utils.Lang
L550: constructor(numerator: number, denominator: number);
  // @since 9 | @atomicservice [since 12] | @syscap SystemCapability.Utils.Lang | @deprecated since 9 | @since 8
L559: constructor();
  // @since 9 | @atomicservice [since 12] | @syscap SystemCapability.Utils.Lang | @deprecated since 9 | @since 8
L579: static parseRationalNumber(numerator: number, denominator: number): RationalNumber;
  // @since 8 | @atomicservice [since 12] | @syscap SystemCapability.Utils.Lang | @since 9 | @deprecated since 9
L596: static createRationalFromString(rationalString: string): RationalNumber;
  // @deprecated since 9 | @since 8 | @syscap SystemCapability.Utils.Lang | @atomicservice [since 12] | @since 9
L607: compareTo(another: RationalNumber): number;
  // @since 9 | @atomicservice [since 12] | @syscap SystemCapability.Utils.Lang | @deprecated since 9 | @since 8
L618: compare(another: RationalNumber): number;
  // @since 8 | @atomicservice [since 12] | @syscap SystemCapability.Utils.Lang | @since 9 | @deprecated since 9
L630: equals(obj: Object): boolean;
  // @since 8 | @atomicservice [since 12] | @syscap SystemCapability.Utils.Lang | @since 9 | @deprecated since 9
L640: valueOf(): number;
  // @deprecated since 9 | @since 8 | @syscap SystemCapability.Utils.Lang | @atomicservice [since 12] | @since 9
L652: static getCommonDivisor(number1: number, number2: number): number;
  // @since 9 | @atomicservice [since 12] | @syscap SystemCapability.Utils.Lang | @deprecated since 9 | @since 8
L671: static getCommonFactor(number1: number, number2: number): number;
  // @since 8 | @atomicservice [since 12] | @syscap SystemCapability.Utils.Lang | @since 9 | @deprecated since 9
L681: getDenominator(): number;
  // @since 8 | @atomicservice [since 12] | @syscap SystemCapability.Utils.Lang | @since 9 | @deprecated since 9
L691: getNumerator(): number;
  // @since 8 | @atomicservice [since 12] | @syscap SystemCapability.Utils.Lang | @since 9 | @deprecated since 9
L702: isFinite(): boolean;
  // @since 8 | @atomicservice [since 12] | @syscap SystemCapability.Utils.Lang | @since 9 | @deprecated since 9
L713: isNaN(): boolean;
  // @since 8 | @atomicservice [since 12] | @syscap SystemCapability.Utils.Lang | @since 9
L724: isZero(): boolean;
  // @since 8 | @atomicservice [since 12] | @syscap SystemCapability.Utils.Lang | @since 9
L736: toString(): string;
  // @deprecated since 9 | @since 8 | @syscap SystemCapability.Utils.Lang | @atomicservice [since 12]
L746: class LruBuffer<K, V> {
  // @deprecated since 9 | @since 8 | @syscap SystemCapability.Utils.Lang
L756: constructor(capacity?: number);
  // @deprecated since 9 | @since 8 | @syscap SystemCapability.Utils.Lang
L766: updateCapacity(newCapacity: number): void;
  // @deprecated since 9 | @since 8 | @syscap SystemCapability.Utils.Lang
L776: toString(): string;
  // @deprecated since 9 | @since 8 | @syscap SystemCapability.Utils.Lang
L785: length: number;
  // @deprecated since 9 | @since 8 | @syscap SystemCapability.Utils.Lang
L795: getCapacity(): number;
  // @deprecated since 9 | @since 8 | @syscap SystemCapability.Utils.Lang
L805: clear(): void;
  // @deprecated since 9 | @since 8 | @syscap SystemCapability.Utils.Lang
L815: getCreateCount(): number;
  // @deprecated since 9 | @since 8 | @syscap SystemCapability.Utils.Lang
L825: getMissCount(): number;
  // @deprecated since 9 | @since 8 | @syscap SystemCapability.Utils.Lang
L835: getRemovalCount(): number;
  // @deprecated since 9 | @since 8 | @syscap SystemCapability.Utils.Lang
L845: getMatchCount(): number;
  // @deprecated since 9 | @since 8 | @syscap SystemCapability.Utils.Lang
L855: getPutCount(): number;
  // @deprecated since 9 | @since 8 | @syscap SystemCapability.Utils.Lang
L865: isEmpty(): boolean;
  // @deprecated since 9 | @since 8 | @syscap SystemCapability.Utils.Lang
L876: get(key: K): V | undefined;
  // @deprecated since 9 | @since 8 | @syscap SystemCapability.Utils.Lang
L889: put(key: K, value: V): V;
  // @deprecated since 9 | @since 8 | @syscap SystemCapability.Utils.Lang
L899: values(): V[];
  // @deprecated since 9 | @since 8 | @syscap SystemCapability.Utils.Lang
L909: keys(): K[];
  // @deprecated since 9 | @since 8 | @syscap SystemCapability.Utils.Lang
L921: remove(key: K): V | undefined;
  // @deprecated since 9 | @since 8 | @syscap SystemCapability.Utils.Lang
L936: afterRemoval(isEvict: boolean, key: K, value: V, newValue: V): void;
  // @deprecated since 9 | @since 8 | @syscap SystemCapability.Utils.Lang
L948: contains(key: K): boolean;
  // @deprecated since 9 | @since 8 | @syscap SystemCapability.Utils.Lang
L959: createDefault(key: K): V;
  // @deprecated since 9 | @since 8 | @syscap SystemCapability.Utils.Lang
L969: entries(): IterableIterator<[ K, V ]>;
  // @since 9 | @atomicservice [since 12] | @syscap SystemCapability.Utils.Lang | @deprecated since 9 | @since 8
L998: class LRUCache<K, V> {
  // @since 9 | @atomicservice [since 12] | @syscap SystemCapability.Utils.Lang
L1009: constructor(capacity?: number);
  // @since 9 | @atomicservice [since 12] | @syscap SystemCapability.Utils.Lang
L1021: updateCapacity(newCapacity: number): void;
  // @since 9 | @atomicservice [since 12] | @syscap SystemCapability.Utils.Lang
L1031: toString(): string;
  // @since 9 | @atomicservice [since 12] | @syscap SystemCapability.Utils.Lang
L1040: length: number;
  // @since 9 | @atomicservice [since 12] | @syscap SystemCapability.Utils.Lang
L1050: getCapacity(): number;
  // @since 9 | @atomicservice [since 12] | @syscap SystemCapability.Utils.Lang
L1059: clear(): void;
  // @since 9 | @atomicservice [since 12] | @syscap SystemCapability.Utils.Lang
L1069: getCreateCount(): number;
  // @since 9 | @atomicservice [since 12] | @syscap SystemCapability.Utils.Lang
L1079: getMissCount(): number;
  // @since 9 | @atomicservice [since 12] | @syscap SystemCapability.Utils.Lang
L1089: getRemovalCount(): number;
  // @since 9 | @atomicservice [since 12] | @syscap SystemCapability.Utils.Lang
L1099: getMatchCount(): number;
  // @since 9 | @atomicservice [since 12] | @syscap SystemCapability.Utils.Lang
L1109: getPutCount(): number;
  // @since 9 | @atomicservice [since 12] | @syscap SystemCapability.Utils.Lang
L1119: isEmpty(): boolean;
  // @since 9 | @atomicservice [since 12] | @syscap SystemCapability.Utils.Lang
L1135: get(key: K): V | undefined;
  // @since 9 | @atomicservice [since 12] | @syscap SystemCapability.Utils.Lang
L1148: put(key: K, value: V): V;
  // @since 9 | @atomicservice [since 12] | @syscap SystemCapability.Utils.Lang
L1158: values(): V[];
  // @since 9 | @atomicservice [since 12] | @syscap SystemCapability.Utils.Lang
L1168: keys(): K[];
  // @since 9 | @atomicservice [since 12] | @syscap SystemCapability.Utils.Lang
L1182: remove(key: K): V | undefined;
  // @since 9 | @atomicservice [since 12] | @syscap SystemCapability.Utils.Lang
L1207: afterRemoval(isEvict: boolean, key: K, value: V, newValue: V): void;
  // @since 9 | @atomicservice [since 12] | @syscap SystemCapability.Utils.Lang
L1219: contains(key: K): boolean;
  // @since 9 | @atomicservice [since 12] | @syscap SystemCapability.Utils.Lang
L1231: createDefault(key: K): V;
  // @since 9 | @atomicservice [since 12] | @syscap SystemCapability.Utils.Lang
L1242: entries(): IterableIterator<[ K, V ]>;
  // @since 7 | @atomicservice [since 12] | @syscap SystemCapability.Utils.Lang | @since 9
L1269: interface ScopeComparable {
  // @since 8 | @atomicservice [since 12] | @syscap SystemCapability.Utils.Lang
L1281: compareTo(other: ScopeComparable): boolean;
  // @since 8 | @atomicservice [since 12] | @syscap SystemCapability.Utils.Lang
L1293: type ScopeType = ScopeComparable | number;
  // @deprecated since 9 | @since 8 | @syscap SystemCapability.Utils.Lang
L1302: class Scope {
  // @deprecated since 9 | @since 8 | @syscap SystemCapability.Utils.Lang
L1313: constructor(lowerObj: ScopeType, upperObj: ScopeType);
  // @deprecated since 9 | @since 8 | @syscap SystemCapability.Utils.Lang
L1323: toString(): string;
  // @deprecated since 9 | @since 8 | @syscap SystemCapability.Utils.Lang
L1334: intersect(range: Scope): Scope;
  // @deprecated since 9 | @since 8 | @syscap SystemCapability.Utils.Lang
L1346: intersect(lowerObj: ScopeType, upperObj: ScopeType): Scope;
  // @deprecated since 9 | @since 8 | @syscap SystemCapability.Utils.Lang
L1356: getUpper(): ScopeType;
  // @deprecated since 9 | @since 8 | @syscap SystemCapability.Utils.Lang
L1366: getLower(): ScopeType;
  // @deprecated since 9 | @since 8 | @syscap SystemCapability.Utils.Lang
L1378: expand(lowerObj: ScopeType, upperObj: ScopeType): Scope;
  // @deprecated since 9 | @since 8 | @syscap SystemCapability.Utils.Lang
L1389: expand(range: Scope): Scope;
  // @deprecated since 9 | @since 8 | @syscap SystemCapability.Utils.Lang
L1400: expand(value: ScopeType): Scope;
  // @deprecated since 9 | @since 8 | @syscap SystemCapability.Utils.Lang
L1412: contains(value: ScopeType): boolean;
  // @deprecated since 9 | @since 8 | @syscap SystemCapability.Utils.Lang
L1424: contains(range: Scope): boolean;
  // @deprecated since 9 | @since 8 | @syscap SystemCapability.Utils.Lang
L1437: clamp(value: ScopeType): ScopeType;
  // @since 9 | @atomicservice [since 12] | @syscap SystemCapability.Utils.Lang | @deprecated since 9 | @since 8
L1448: class ScopeHelper {
  // @since 9 | @atomicservice [since 12] | @syscap SystemCapability.Utils.Lang
L1459: constructor(lowerObj: ScopeType, upperObj: ScopeType);
  // @since 9 | @atomicservice [since 12] | @syscap SystemCapability.Utils.Lang
L1469: toString(): string;
  // @since 9 | @atomicservice [since 12] | @syscap SystemCapability.Utils.Lang
L1481: intersect(range: ScopeHelper): ScopeHelper;
  // @since 9 | @atomicservice [since 12] | @syscap SystemCapability.Utils.Lang
L1494: intersect(lowerObj: ScopeType, upperObj: ScopeType): ScopeHelper;
  // @since 9 | @atomicservice [since 12] | @syscap SystemCapability.Utils.Lang
L1504: getUpper(): ScopeType;
  // @since 9 | @atomicservice [since 12] | @syscap SystemCapability.Utils.Lang
L1514: getLower(): ScopeType;
  // @since 9 | @atomicservice [since 12] | @syscap SystemCapability.Utils.Lang
L1525: expand(lowerObj: ScopeType, upperObj: ScopeType): ScopeHelper;
  // @since 9 | @atomicservice [since 12] | @syscap SystemCapability.Utils.Lang
L1536: expand(range: ScopeHelper): ScopeHelper;
  // @since 9 | @atomicservice [since 12] | @syscap SystemCapability.Utils.Lang
L1547: expand(value: ScopeType): ScopeHelper;
  // @since 9 | @atomicservice [since 12] | @syscap SystemCapability.Utils.Lang
L1559: contains(value: ScopeType): boolean;
  // @since 9 | @atomicservice [since 12] | @syscap SystemCapability.Utils.Lang
L1571: contains(range: ScopeHelper): boolean;
  // @since 9 | @atomicservice [since 12] | @syscap SystemCapability.Utils.Lang
L1584: clamp(value: ScopeType): ScopeType;
  // @deprecated since 9 | @since 8 | @syscap SystemCapability.Utils.Lang | @since 9 | @atomicservice [since 12]
L1594: class Base64 {
  // @deprecated since 9 | @since 8 | @syscap SystemCapability.Utils.Lang
L1603: constructor();
  // @deprecated since 9 | @since 8 | @syscap SystemCapability.Utils.Lang
L1614: encodeSync(src: Uint8Array): Uint8Array;
  // @deprecated since 9 | @since 8 | @syscap SystemCapability.Utils.Lang
L1625: encodeToStringSync(src: Uint8Array): string;
  // @deprecated since 9 | @since 8 | @syscap SystemCapability.Utils.Lang
L1636: decodeSync(src: Uint8Array | string): Uint8Array;
  // @deprecated since 9 | @since 8 | @syscap SystemCapability.Utils.Lang
L1647: encode(src: Uint8Array): Promise<Uint8Array>;
  // @deprecated since 9 | @since 8 | @syscap SystemCapability.Utils.Lang
L1658: encodeToString(src: Uint8Array): Promise<string>;
  // @deprecated since 9 | @since 8 | @syscap SystemCapability.Utils.Lang
L1669: decode(src: Uint8Array | string): Promise<Uint8Array>;
  // @since 10 | @atomicservice [since 11] | @syscap SystemCapability.Utils.Lang | @deprecated since 9 | @since 8
L1679: enum Type {
  // @since 9 | @atomicservice [since 11] | @syscap SystemCapability.Utils.Lang | @since 12 | @atomicservice | @since 10
L1739: class Base64Helper {
  // @since 9 | @atomicservice [since 11] | @syscap SystemCapability.Utils.Lang
L1748: constructor();
  // @since 9 | @atomicservice [since 11] | @syscap SystemCapability.Utils.Lang
L1761: encodeSync(src: Uint8Array, options?: Type): Uint8Array;
  // @since 9 | @atomicservice [since 11] | @syscap SystemCapability.Utils.Lang
L1790: encodeToStringSync(src: Uint8Array, options?: Type): string;
  // @since 9 | @atomicservice [since 11] | @syscap SystemCapability.Utils.Lang
L1806: decodeSync(src: Uint8Array | string, options?: Type): Uint8Array;
  // @since 9 | @atomicservice [since 11] | @syscap SystemCapability.Utils.Lang
L1819: encode(src: Uint8Array, options?: Type): Promise<Uint8Array>;
  // @since 9 | @atomicservice [since 12] | @syscap SystemCapability.Utils.Lang | @atomicservice [since 11]
L1836: encodeToString(src: Uint8Array, options?: Type): Promise<string>;
  // @since 9 | @atomicservice [since 12] | @syscap SystemCapability.Utils.Lang | @atomicservice [since 11]
L1852: decode(src: Uint8Array | string, options?: Type): Promise<Uint8Array>;
  // @since 8 | @atomicservice [since 12] | @syscap SystemCapability.Utils.Lang | @since 9 | @atomicservice [since 11]
L1863: class types {
  // @since 8 | @atomicservice [since 12] | @syscap SystemCapability.Utils.Lang
L1872: constructor();
  // @since 8 | @atomicservice [since 12] | @syscap SystemCapability.Utils.Lang
L1884: isAnyArrayBuffer(value: Object): boolean;
  // @since 8 | @atomicservice [since 12] | @syscap SystemCapability.Utils.Lang
L1896: isArrayBufferView(value: Object): boolean;
  // @since 8 | @atomicservice [since 12] | @syscap SystemCapability.Utils.Lang
L1908: isArgumentsObject(value: Object): boolean;
  // @since 8 | @atomicservice [since 12] | @syscap SystemCapability.Utils.Lang
L1920: isArrayBuffer(value: Object): boolean;
  // @since 8 | @atomicservice [since 12] | @syscap SystemCapability.Utils.Lang
L1932: isAsyncFunction(value: Object): boolean;
  // @since 8 | @atomicservice [since 12] | @syscap SystemCapability.Utils.Lang
L1944: isBigInt64Array(value: Object): boolean;
  // @since 8 | @atomicservice [since 12] | @syscap SystemCapability.Utils.Lang
L1956: isBigUint64Array(value: Object): boolean;
  // @deprecated since 14 | @since 8 | @atomicservice [since 12] | @syscap SystemCapability.Utils.Lang
L1973: isBooleanObject(value: Object): boolean;
  // @deprecated since 14 | @since 8 | @atomicservice [since 12] | @syscap SystemCapability.Utils.Lang
L1990: isBoxedPrimitive(value: Object): boolean;
  // @since 8 | @atomicservice [since 12] | @syscap SystemCapability.Utils.Lang | @deprecated since 14
L2002: isDataView(value: Object): boolean;
  // @since 8 | @atomicservice [since 12] | @syscap SystemCapability.Utils.Lang | @deprecated since 14
L2014: isDate(value: Object): boolean;
  // @since 8 | @atomicservice [since 12] | @syscap SystemCapability.Utils.Lang | @deprecated since 14
L2026: isExternal(value: Object): boolean;
  // @since 8 | @atomicservice [since 12] | @syscap SystemCapability.Utils.Lang | @deprecated since 14
L2038: isFloat32Array(value: Object): boolean;
  // @since 8 | @atomicservice [since 12] | @syscap SystemCapability.Utils.Lang | @deprecated since 14
L2050: isFloat64Array(value: Object): boolean;
  // @since 8 | @atomicservice [since 12] | @syscap SystemCapability.Utils.Lang
L2062: isGeneratorFunction(value: Object): boolean;
  // @since 8 | @atomicservice [since 12] | @syscap SystemCapability.Utils.Lang
L2074: isGeneratorObject(value: Object): boolean;
  // @since 8 | @atomicservice [since 12] | @syscap SystemCapability.Utils.Lang
L2086: isInt8Array(value: Object): boolean;
  // @since 8 | @atomicservice [since 12] | @syscap SystemCapability.Utils.Lang
L2098: isInt16Array(value: Object): boolean;
  // @since 8 | @atomicservice [since 12] | @syscap SystemCapability.Utils.Lang
L2110: isInt32Array(value: Object): boolean;
  // @since 8 | @atomicservice [since 12] | @syscap SystemCapability.Utils.Lang
L2122: isMap(value: Object): boolean;
  // @since 8 | @atomicservice [since 12] | @syscap SystemCapability.Utils.Lang
L2134: isMapIterator(value: Object): boolean;
  // @since 8 | @atomicservice [since 12] | @syscap SystemCapability.Utils.Lang
L2146: isModuleNamespaceObject(value: Object): boolean;
  // @since 8 | @atomicservice [since 12] | @syscap SystemCapability.Utils.Lang
L2158: isNativeError(value: Object): boolean;
  // @deprecated since 14 | @since 8 | @atomicservice [since 12] | @syscap SystemCapability.Utils.Lang
L2175: isNumberObject(value: Object): boolean;
  // @since 8 | @atomicservice [since 12] | @syscap SystemCapability.Utils.Lang | @deprecated since 14
L2187: isPromise(value: Object): boolean;
  // @since 8 | @atomicservice [since 12] | @syscap SystemCapability.Utils.Lang | @deprecated since 14
L2199: isProxy(value: Object): boolean;
  // @since 8 | @atomicservice [since 12] | @syscap SystemCapability.Utils.Lang | @deprecated since 14
L2211: isRegExp(value: Object): boolean;
  // @since 8 | @atomicservice [since 12] | @syscap SystemCapability.Utils.Lang | @deprecated since 14
L2223: isSet(value: Object): boolean;
  // @since 8 | @atomicservice [since 12] | @syscap SystemCapability.Utils.Lang | @deprecated since 14
L2235: isSetIterator(value: Object): boolean;
  // @since 8 | @atomicservice [since 12] | @syscap SystemCapability.Utils.Lang
L2247: isSharedArrayBuffer(value: Object): boolean;
  // @deprecated since 14 | @since 8 | @atomicservice [since 12] | @syscap SystemCapability.Utils.Lang
L2264: isStringObject(value: Object): boolean;
  // @deprecated since 14 | @since 8 | @atomicservice [since 12] | @syscap SystemCapability.Utils.Lang
L2281: isSymbolObject(value: Object): boolean;
  // @since 8 | @atomicservice [since 12] | @syscap SystemCapability.Utils.Lang | @deprecated since 14
L2293: isTypedArray(value: Object): boolean;
  // @since 8 | @atomicservice [since 12] | @syscap SystemCapability.Utils.Lang | @deprecated since 14
L2305: isUint8Array(value: Object): boolean;
  // @since 8 | @atomicservice [since 12] | @syscap SystemCapability.Utils.Lang | @deprecated since 14
L2317: isUint8ClampedArray(value: Object): boolean;
  // @since 8 | @atomicservice [since 12] | @syscap SystemCapability.Utils.Lang | @deprecated since 14
L2329: isUint16Array(value: Object): boolean;
  // @since 8 | @atomicservice [since 12] | @syscap SystemCapability.Utils.Lang | @deprecated since 14
L2341: isUint32Array(value: Object): boolean;
  // @since 8 | @atomicservice [since 12] | @syscap SystemCapability.Utils.Lang
L2353: isWeakMap(value: Object): boolean;
  // @since 8 | @atomicservice [since 12] | @syscap SystemCapability.Utils.Lang
L2365: isWeakSet(value: Object): boolean;
  // @since 11 | @atomicservice [since 12] | @syscap SystemCapability.Utils.Lang | @since 8
L2376: class Aspect {
  // @since 11 | @atomicservice [since 12] | @syscap SystemCapability.Utils.Lang
L2395: static addBefore(targetClass: Object, methodName: string, isStatic: boolean, before: Function): void;
  // @since 11 | @atomicservice [since 12] | @syscap SystemCapability.Utils.Lang
L2415: static addAfter(targetClass: Object, methodName: string, isStatic: boolean, after: Function): void;
  // @since 11 | @atomicservice [since 12] | @syscap SystemCapability.Utils.Lang
L2434: static replace(targetClass: Object, methodName: string, isStatic: boolean, instead: Function): void;
  // @since 12 | @atomicservice | @syscap SystemCapability.Utils.Lang | @since 11 | @atomicservice [since 12]
L2445: class StringDecoder {
  // @since 12 | @atomicservice | @syscap SystemCapability.Utils.Lang
L2455: constructor(encoding?: string);
  // @since 12 | @atomicservice | @syscap SystemCapability.Utils.Lang
L2469: write(chunk: string | Uint8Array): string;
  // @since 12 | @atomicservice | @syscap SystemCapability.Utils.Lang
L2480: end(chunk?: string | Uint8Array): string;
  // @since 20 | @atomicservice | @syscap SystemCapability.Utils.Lang | @since 12
L2494: function getMainThreadStackTrace(): string;
  // @since 22 | @atomicservice | @syscap SystemCapability.Utils.Lang
L2504: interface AutoFinalizer<T> {
  // @since 22 | @atomicservice | @syscap SystemCapability.Utils.Lang
L2514: onFinalization(heldValue: T): void;
  // @since 22 | @atomicservice | @syscap SystemCapability.Utils.Lang
L2524: class AutoFinalizerCleaner<T> {
  // @since 22 | @atomicservice | @syscap SystemCapability.Utils.Lang
L2535: static register<T>(obj: AutoFinalizer<T>, heldValue: T): void;
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.Utils.Lang | @since 22 | @atomicservice
L2545: interface MultithreadingDetectionOptions {
  // @since 23 | @stagemodelonly | @syscap SystemCapability.Utils.Lang | @since 26.0.0
L2587: class ArkTSVM {
  // @since 23 | @stagemodelonly | @syscap SystemCapability.Utils.Lang
L2602: static setMultithreadingDetectionEnabled(enabled: boolean, options?: MultithreadingDetectionOptions): void;
  // @since 24 | @stagemodelonly | @syscap SystemCapability.Utils.Lang | @since 23
L2622: static onVMHeapMemoryPressure(callback: Callback<string>, heapMemoryThreshold: HeapMemoryThreshold): boolean;
  // @since 24 | @stagemodelonly | @syscap SystemCapability.Utils.Lang | @since 23
L2631: static offVMHeapMemoryPressure(): void;
  // @since 24 | @stagemodelonly | @syscap SystemCapability.Utils.Lang | @since 23
L2641: static getAllVMHeapMemoryInfo(): Promise<HeapMemoryInfo[]>;
  // @since 24 | @stagemodelonly | @syscap SystemCapability.Utils.Lang | @since 23
L2650: static enableLocalHandleDetection(): void;
  // @since 26.0.0 | @stagemodelonly | @syscap SystemCapability.Utils.Lang | @since 24 | @since 23
L2663: static setTrackGlobalRef(enable: boolean): void;
  // @since 24 | @stagemodelonly | @syscap SystemCapability.Utils.Lang | @since 26.0.0
L2672: interface HeapMemoryInfo {
  // @since 24 | @stagemodelonly | @syscap SystemCapability.Utils.Lang
L2701: heapType: string;
  // @since 24 | @stagemodelonly | @syscap SystemCapability.Utils.Lang
L2710: heapObjectSize: number;
  // @since 24 | @stagemodelonly | @syscap SystemCapability.Utils.Lang
L2720: interface HeapMemoryThreshold {
```

