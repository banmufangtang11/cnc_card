# CNC控制卡FPGA模块功能与层级关系文档

## 1. 系统概述

本项目是一个基于FPGA的CNC控制卡设计，采用PCIe Gen1 x4接口与上位机通信，实现4轴(X/Y/Z/A)运动控制、编码器反馈、手轮输入、刀具换刀等功能。系统采用模块化设计，各功能模块职责清晰，便于维护和扩展。

---

## 2. 模块层级结构图

```
CNC_CARD (顶层测试模块)
├── PCIECORE (PCIe核心接口)
│   ├── PCIEbot (PCIe物理/链路层)
│   │   ├── PCIe_hard_plus (PCIe硬核)
│   │   └── altpcierd_reconfig_clk_pll (PLL时钟)
│   ├── rsstinf (Avalon-ST转FIFO)
│   ├── txproc (PCIe发送事务处理)
│   └── cfgspace (PCIe配置空间)
├── altpll0 (时钟生成器 100MHz→100/40/50MHz)
├── fifo33 (运动指令缓冲区)
├── fifo31 (PCIe接收数据缓冲区)
├── ext_inf (外部接口)
├── test_fifo (FIFO数据传输控制)
├── dda (DDA插补模块)
│   └── interpolation ×4 (插补器)
├── jog (JOG手动控制)
├── hand_wheel (手轮输入)
│   ├── queue (手轮周期缓存FIFO)
│   ├── puls_hw (手轮脉冲倍频)
│   ├── fsm_hw (手轮状态机)
│   ├── axis_sel (轴选择)
│   └── filter_encode ×2 (信号滤波)
├── jog_sel (手轮/JOG选择)
├── zero_sel (回零/JOG选择)
├── sel_assign (运动模式选择)
├── check (运行状态检测)
├── clk_2ms (2ms时钟生成)
├── key_hold (按钮消抖)
├── motor_ctrl (Z轴回零控制)
│   ├── key_gen (按钮消抖)
│   └── state_ctrl (回零状态机)
│       └── line_rom_ip (S曲线ROM)
├── motor_ctrl_xy (X/Y轴回零控制)
│   ├── key_gen (按钮消抖)
│   └── state_ctrl_xy (回零状态机)
│       └── line_rom_ip (S曲线ROM)
├── tool_set_ctrl (刀具测量控制)
├── tool_mag_ctrl (刀具换刀控制)
├── aux_fbac (辅助功能反馈)
├── co_assign (轴信号分配)
├── filter_encode ×8 (编码器滤波)
├── encode_pd ×3 (X/Y/Z轴编码器计数)
├── encode_pd_a (A轴编码器计数)
└── pctocard_count ×4 (卡位置计数)
```

---

## 3. 模块功能详细说明

### 3.1 顶层模块

| 模块名称 | 文件路径 | 功能描述 |
|---------|---------|---------|
| **CNC_CARD** | rtl/CNC_CARD.v | 系统顶层模块，集成所有子模块，协调数据流向和控制信号，提供完整的CNC控制卡功能 |

---

### 3.2 PCIe接口层

#### 3.2.1 核心接口模块

| 模块名称 | 文件路径 | 功能描述 | 父模块 |
|---------|---------|---------|---------|
| **PCIECORE** | rtl/PCIECORE.v | PCIe核心接口模块，集成物理层、事务层、配置空间和FIFO接口，协调PCIEbot、rsstinf、txproc、cfgspace | CNC_CARD |
| **PCIEbot** | rtl/PCIEbot.v | PCIe物理层和数据链路层核心，集成PCIe_hard_plus硬核和PLL时钟生成器 | PCIECORE |

#### 3.2.2 事务处理模块

| 模块名称 | 文件路径 | 功能描述 | 父模块 |
|---------|---------|---------|---------|
| **txproc** | rtl/txproc.v | PCIe发送事务处理，生成TX TLP包，管理中断，控制CNC运动寄存器（软运动、主轴、辅助控制） | PCIECORE |
| **rxproc** | rtl/rxproc.v | PCIe接收事务处理，解析RX TLP包，处理内存读写、IO和配置事务（由txproc内部调用） | PCIECORE |
| **rsstinf** | rtl/rsstinf.v | Avalon-ST 64位流到96位FIFO格式转换，处理RX数据写入FIFO | PCIECORE |
| **cfgspace** | rtl/cfgspace.v | PCIe配置空间管理，处理设备状态、命令、总线/设备号等配置寄存器的读写 | PCIECORE |

#### 3.2.3 IP核模块

| 模块名称 | 文件路径 | 功能描述 | 父模块 |
|---------|---------|---------|---------|
| **PCIe_hard_plus** | ip/pcie_hard/PCIe_hard_plus.v | PCIe硬核顶层，实现物理层(SerDes)和数据链路层协议 | PCIEbot |
| **altpcierd_reconfig_clk_pll** | ip/pcie_hard/ | PLL时钟生成器，产生reconfig_clk和tlpclk(100MHz) | PCIEbot |
| **altpll0** | rtl/altpll0.v | 系统时钟生成器，将100MHz输入时钟分频为100MHz、40MHz、50MHz | CNC_CARD |

---

### 3.3 运动控制层

#### 3.3.1 插补模块

| 模块名称 | 文件路径 | 功能描述 | 父模块 |
|---------|---------|---------|---------|
| **dda** | rtl/dda.v | DDA插补模块，将32位指令数据分解为4轴(X/Y/Z/A)的插补参数，分别驱动4个interpolation模块 | CNC_CARD |
| **interpolation** | rtl/interpolation.v | 核心插补器，基于累加器原理生成脉冲信号 | dda |

#### 3.3.2 JOG控制模块

| 模块名称 | 文件路径 | 功能描述 | 父模块 |
|---------|---------|---------|---------|
| **jog** | rtl/jog.v | JOG手动控制模块，处理手动按钮产生的连续脉冲，支持6档速度选择(s1-s6) | CNC_CARD |
| **jog_sel** | rtl/jog_sel.v | 手轮/JOG选择模块，根据hw_valid信号选择手轮或JOG作为控制源 | CNC_CARD |

#### 3.3.3 运动选择模块

| 模块名称 | 文件路径 | 功能描述 | 父模块 |
|---------|---------|---------|---------|
| **sel_assign** | rtl/sel_assign.v | 运动选择模块，选择DDA插补模式或手动运动模式(JOG/手轮/回零) | CNC_CARD |
| **zero_sel** | rtl/zero_sel.v | 回零选择模块，在回零模式和JOG模式之间切换 | CNC_CARD |

#### 3.3.4 运行控制模块

| 模块名称 | 文件路径 | 功能描述 | 父模块 |
|---------|---------|---------|---------|
| **check** | rtl/check.v | 运行状态检测模块，检测start/stop信号，控制插补valid输出，实现启动/停止逻辑 | CNC_CARD |
| **clk_2ms** | rtl/clk_2ms.v | 2ms时钟生成模块，产生FIFO读使能信号，控制指令读取速率 | CNC_CARD |

---

### 3.4 编码器处理层

| 模块名称 | 文件路径 | 功能描述 | 父模块 |
|---------|---------|---------|---------|
| **filter_encode** | rtl/filter_encode.v | 编码器滤波模块，对编码器A/B相信号进行RC滤波和去抖处理 | CNC_CARD, hand_wheel |
| **encode_pd** | rtl/encode_pd.v | 编码器脉冲计数模块(X/Y/Z轴)，实现4倍频计数，输出增量计数(delta)和总量计数(count) | CNC_CARD |
| **encode_pd_a** | rtl/encode_pd_a.v | 编码器脉冲计数模块(A轴)，支持正/负方向计数 | CNC_CARD |
| **pctocard_count** | rtl/pctocard_count.v | 卡位置计数模块，记录DDA插补产生的脉冲数，用于PCIe发送回上位机 | CNC_CARD |

---

### 3.5 手轮控制层

| 模块名称 | 文件路径 | 功能描述 | 父模块 |
|---------|---------|---------|---------|
| **hand_wheel** | rtl/hand_wheel.v | 手轮输入模块，处理手轮脉冲，支持X1/X10/X100倍率选择和X/Y/Z/A轴选择 | CNC_CARD |
| **axis_sel** | rtl/axis_sel.v | 轴选择模块，根据手轮轴选择信号(i_X/i_Y/i_Z/i_A)将脉冲分配到对应轴 | hand_wheel |
| **fsm_hw** | rtl/fsm_hw.v | 手轮状态机模块，实现A/B相鉴相和周期测量，将测量结果写入FIFO | hand_wheel |
| **puls_hw** | rtl/puls_hw.v | 手轮脉冲倍频模块，根据倍率选择(X1/X10/X100)生成对应频率的脉冲 | hand_wheel |
| **queue** | (IP核) | 手轮周期缓存FIFO，缓存fsm_hw测量的周期数据 | hand_wheel |

---

### 3.6 回零控制层

| 模块名称 | 文件路径 | 功能描述 | 父模块 |
|---------|---------|---------|---------|
| **motor_ctrl** | rtl/motor_ctrl.v | 电机控制模块(Z轴回零)，集成key_gen和state_ctrl，实现Z轴自动回零 | CNC_CARD |
| **motor_ctrl_xy** | rtl/motor_ctrl_xy.v | 电机控制模块(X/Y轴回零)，集成key_gen和state_ctrl_xy，支持Z轴完成后启动 | CNC_CARD |
| **state_ctrl** | rtl/state_ctrl.v | Z轴回零状态机，包含IDLE→FAST→SLOW→IDLE/LIMIT→BACK→FAST状态转换 | motor_ctrl |
| **state_ctrl_xy** | rtl/state_ctrl_xy.v | X/Y轴回零状态机，支持Z轴完成信号(z_finished)触发 | motor_ctrl_xy |
| **key_gen** | rtl/key_gen.v | 按钮消抖模块，对零位开关、接近开关、限位开关进行消抖处理 | motor_ctrl, motor_ctrl_xy |
| **line_rom_ip** | (IP核) | S曲线速度规划ROM，存储回零时的速度参数，实现平滑加减速 | state_ctrl, state_ctrl_xy |

---

### 3.7 刀具控制层

| 模块名称 | 文件路径 | 功能描述 | 父模块 |
|---------|---------|---------|---------|
| **tool_set_ctrl** | rtl/tool_set_ctrl.v | 刀具测量控制模块，根据辅助控制寄存器(aux_ctl)控制刀具测量器使能 | CNC_CARD |
| **tool_mag_ctrl** | rtl/tool_mag_ctrl.v | 刀具换刀控制模块，控制换刀机构的前进(fw)/后退(bw)/旋转/松刀(loose) | CNC_CARD |
| **aux_fbac** | rtl/aux_fbac.v | 辅助功能反馈模块，收集刀具测量和换刀状态，产生中断请求(aux_intrupt) | CNC_CARD |
| **co_assign** | rtl/co_assign.v | 轴信号分配模块，根据co1-co8选择输出轴，支持换刀机构占用第8轴 | CNC_CARD |

---

### 3.8 辅助模块

| 模块名称 | 文件路径 | 功能描述 | 父模块 |
|---------|---------|---------|---------|
| **ext_inf** | rtl/ext_inf.v | 外部接口模块，处理PCIe与运动控制之间的数据交换，控制FIFO33写入 | CNC_CARD |
| **test_fifo** | rtl/test_fifo.v | FIFO数据传输控制，实现PCIe FIFO到FIFO31的数据搬运 | CNC_CARD |
| **key_hold** | rtl/key_hold.v | 按钮消抖模块，对set_ref和renew_count按钮进行消抖处理 | CNC_CARD |
| **fifo33** | (IP核) | 运动指令缓冲区，32位数据宽度，存储上位机下发的运动指令 | CNC_CARD |
| **fifo31** | (IP核) | PCIe接收数据缓冲区，64位数据宽度，存储PCIe接收到的数据 | CNC_CARD |

---

## 4. 父子关系表

| 父模块 | 子模块 | 数量 |
|---------|-------|------|
| **CNC_CARD** | PCIECORE | 1 |
| **CNC_CARD** | altpll0 | 1 |
| **CNC_CARD** | fifo33 | 1 |
| **CNC_CARD** | fifo31 | 1 |
| **CNC_CARD** | ext_inf | 1 |
| **CNC_CARD** | test_fifo | 1 |
| **CNC_CARD** | dda | 1 |
| **CNC_CARD** | jog | 1 |
| **CNC_CARD** | hand_wheel | 1 |
| **CNC_CARD** | jog_sel | 1 |
| **CNC_CARD** | zero_sel | 1 |
| **CNC_CARD** | sel_assign | 1 |
| **CNC_CARD** | check | 1 |
| **CNC_CARD** | clk_2ms | 1 |
| **CNC_CARD** | key_hold | 2 |
| **CNC_CARD** | motor_ctrl | 1 |
| **CNC_CARD** | motor_ctrl_xy | 2 |
| **CNC_CARD** | tool_set_ctrl | 1 |
| **CNC_CARD** | tool_mag_ctrl | 1 |
| **CNC_CARD** | aux_fbac | 1 |
| **CNC_CARD** | co_assign | 1 |
| **CNC_CARD** | filter_encode | 8 |
| **CNC_CARD** | encode_pd | 3 |
| **CNC_CARD** | encode_pd_a | 1 |
| **CNC_CARD** | pctocard_count | 4 |
| **PCIECORE** | PCIEbot | 1 |
| **PCIECORE** | rsstinf | 1 |
| **PCIECORE** | txproc | 1 |
| **PCIECORE** | cfgspace | 1 |
| **PCIEbot** | PCIe_hard_plus | 1 |
| **PCIEbot** | altpcierd_reconfig_clk_pll | 1 |
| **dda** | interpolation | 4 |
| **hand_wheel** | queue | 1 |
| **hand_wheel** | puls_hw | 1 |
| **hand_wheel** | fsm_hw | 1 |
| **hand_wheel** | axis_sel | 1 |
| **hand_wheel** | filter_encode | 2 |
| **motor_ctrl** | key_gen | 1 |
| **motor_ctrl** | state_ctrl | 1 |
| **motor_ctrl_xy** | key_gen | 1 |
| **motor_ctrl_xy** | state_ctrl_xy | 1 |
| **state_ctrl** | line_rom_ip | 1 |
| **state_ctrl_xy** | line_rom_ip | 1 |

---

## 5. 数据流向说明

### 5.1 PCIe数据接收流程

```
上位机 → PCIe物理层(RX) → PCIEbot → rsstinf → fifo31 → test_fifo → fifo33 → sel_assign → dda → 脉冲输出
                                              ↓
                                        rxproc → extdq → ext_inf → fifo33
```

### 5.2 PCIe数据发送流程

```
编码器位置(count_x/y/z/a) → txproc → PCIEbot → PCIe物理层(TX) → 上位机
卡位置(card_count_x/y/z/a) → txproc → PCIEbot → PCIe物理层(TX) → 上位机
辅助状态(aux_back) → txproc → PCIEbot → PCIe物理层(TX) → 上位机
```

### 5.3 运动控制信号流向

```
上位机指令 → fifo33 → sel_assign → dda → co_assign → 脉冲输出(p1-p8)
                              ↓
                        jog/hand_wheel → jog_sel → zero_sel → sel_assign
                              ↓
                        motor_ctrl → zero_sel → sel_assign
```

### 5.4 编码器反馈流程

```
编码器A/B相 → filter_encode → encode_pd → count_x/y/z/a → txproc → PCIe发送
                                               ↓
                                         delta_x/y/z/a → txproc
```

### 5.5 回零控制流程

```
szero(回零按钮) → key_hold → motor_ctrl → key_gen(消抖) → state_ctrl(状态机) → zero_sel → sel_assign → 脉冲输出
```

### 5.6 手轮控制流程

```
手轮A/B相 → filter_encode → fsm_hw(鉴相/周期测量) → queue(FIFO) → puls_hw(倍频) → axis_sel(轴选择) → jog_sel → zero_sel → sel_assign → 脉冲输出
```

---

## 6. 时钟域说明

| 时钟名称 | 频率 | 来源 | 用途 |
|---------|------|------|------|
| **refclk** | 100MHz | 外部晶振 | PCIe参考时钟 |
| **free100m** | 100MHz | 外部晶振 | 系统自由运行时钟 |
| **tlpclk** | 100MHz | PCIEbot PLL | PCIe事务层时钟，运动控制主时钟 |
| **clk_40m** | 40MHz | altpll0 | 回零控制模块时钟 |
| **clk_50m** | 50MHz | altpll0 | 手轮输入模块时钟 |

---

## 7. 模块依赖关系图

```
                    ┌─────────────────────────────────────────┐
                    │           CNC_CARD (顶层)                │
                    └──────────────────┬──────────────────────┘
                                       │
        ┌──────────────────────────────┼──────────────────────────────┐
        │                              │                              │
┌───────▼───────┐           ┌──────────▼──────────┐          ┌─────────▼─────────┐
│   PCIECORE    │           │     运动控制层       │          │     编码器层      │
│  (PCIe核心)   │           │                    │          │                   │
└───────┬───────┘           └──────────┬──────────┘          └─────────┬─────────┘
        │                              │                              │
  ┌─────┼─────┐           ┌───────────┼───────────┐         ┌──────────┼──────────┐
  │     │     │           │           │           │         │          │          │
┌─▼─┐ ┌─▼─┐ ┌─▼─┐     ┌──▼──┐    ┌───▼───┐   ┌───▼───┐  ┌──▼──┐   ┌───▼───┐  ┌───▼───┐
│   │ │   │ │   │     │ dda  │    │ jog   │   │  sel  │  │filter│   │encode │  │pctoc- │
│bot│ │rs │ │tx │     │(插补)│    │(手动) │   │assign │  │_enc  │   │_pd    │  │ard    │
│   │ │st │ │pr │     └──┬──┘    └───┬───┘   └───┬───┘  └──┬──┘   └───┬───┘  └───┬───┘
└─┬─┘ └─┬─┘ └─┬─┘       │           │           │         │          │          │
  │     │     │      ┌───┴───┐       │           │         │          │          │
  │     │     │      │interp │       │           │         │          │          │
  │     │     │      │olation│       │           │         │          │          │
  │     │     │      └───────┘       │           │         │          │          │
  │     │     │                      │           │         │          │          │
┌─▼─────▼─────▼─┐           ┌────────┴────────┐  │         │          │          │
│  PCIe_hard_   │           │   hand_wheel    │  │         │          │          │
│     plus      │           │   (手轮输入)    │  │         │          │          │
└───────────────┘           └────────┬────────┘  │         │          │          │
                                     │            │         │          │          │
                              ┌──────┼──────┐     │         │          │          │
                              │      │      │     │         │          │          │
                           ┌──▼──┐ ┌─▼─┐ ┌─▼─┐    │         │          │          │
                           │fsm  │ │puls│ │axis│    │         │          │          │
                           │_hw  │ │_hw │ │sel│    │         │          │          │
                           └──────┘ └───┘ └───┘    │         │          │          │
                                                    │         │          │          │
                    ┌───────────────────────────────┼─────────┼──────────┼──────────┘
                    │                               │         │          │
           ┌────────▼────────┐           ┌──────────▼────────┐│          │
           │   回零控制层     │           │    刀具控制层      ││          │
           │                 │           │                   ││          │
           └────────┬────────┘           └──────────┬────────┘│          │
                    │                               │         │          │
           ┌────────┴────────┐           ┌──────────┼────────┐│          │
           │                 │           │          │        ││          │
        ┌──▼──┐         ┌───▼───┐    ┌───▼───┐ ┌───▼───┐ ┌──▼───┐        │
        │motor│         │motor  │    │tool   │ │tool   │ │aux   │        │
        │_ctrl│         │_ctrl_ │    │_set   │ │_mag   │ │fbac  │        │
        │(Z轴)│         │xy(XY) │    │_ctrl  │ │_ctrl  │       │        │
        └──┬──┘         └───┬───┘    └───┬───┘ └───┬───┘ └──────┘        │
           │                 │           │          │                   │
     ┌─────┴─────┐     ┌─────┴─────┐    │          │                   │
     │           │     │           │    │          │                   │
  ┌──▼──┐    ┌───▼───┐┌──▼──┐   ┌──▼───┐│          │                   │
  │key  │    │state  ││key  │   │state ││          │                   │
  │_gen │    │_ctrl  ││_gen │   │_ctrl_││          │                   │
  │     │    │(Z轴)  ││     │   │xy(XY)││          │                   │
  └─────┘    └───┬───┘└─────┘   └───┬───┘│          │                   │
                 │                   │   │          │                   │
              ┌──▼───┐          ┌───▼───┐│          │                   │
              │line  │          │line   ││          │                   │
              │_rom  │          │_rom   ││          │                   │
              │_ip   │          │_ip    ││          │                   │
              └──────┘          └───────┘│          │                   │
                                         │          │                   │
                                   ┌─────┴──────────┴───────────────────┘
                                   │
                              ┌────▼────┐
                              │co_assign│
                              │(轴分配) │
                              └────┬────┘
                                   │
                              ┌────▼────┐
                              │ 脉冲输出 │
                              │ p1-p8   │
                              └─────────┘
```

---

## 8. 设计特点总结

1. **模块化设计**：各功能模块职责单一，便于独立测试和维护
2. **分层架构**：PCIe接口层、运动控制层、编码器处理层、辅助控制层清晰分离
3. **多时钟域设计**：支持100MHz/40MHz/50MHz多时钟域，满足不同模块的时序要求
4. **FIFO缓冲**：使用双口RAM实现PCIe数据和运动指令的缓冲，提高系统稳定性
5. **状态机控制**：回零控制、换刀控制等复杂逻辑采用状态机实现，逻辑清晰
6. **信号滤波**：编码器信号和按钮输入均经过滤波处理，提高抗干扰能力
7. **运动模式切换**：支持自动插补、JOG手动、手轮、回零四种运动模式的无缝切换