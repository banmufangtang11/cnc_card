/***************************************************************************
 整个系统的主头文件cnc.h      包含宏定义，类型定义，结构体定义 （不完全，根据需要可增减）
 ***************************************************************************/
#ifndef CNC_H
#define CNC_H 

//调试任务管理模块宏定义（可删除）
#define DEBUG_TASKMANAGE
#define  OUTPUT

//系统默认零点
#define DEFAULT_HOME_X  0.0
#define DEFAULT_HOME_Y  0.0
#define DEFAULT_HOME_Z  0.0

//类型定义
typedef int ON_OFF;
#define OFF 0
#define ON 1

//运动指令类型定义
#define MOTION_TYPE_TRAVERSE 1
#define MOTION_TYPE_FEED 2
#define MOTION_TYPE_ARC 3
#define MOTION_TYPE_TOOLCHANGE 4
#define MOTION_TYPE_PROBING 5

//程序数组范围定义
#define LINE_LEN 256
#define NAME_LEN 256
#define COMMENT_LEN 256
#define BUFFERLEN 80
#define G_GROUP 16
#define M_GROUP  11
#define OTHER_GROUP 4

//任务运行方式
typedef int TASK_MODE;
#define AUTO_MODE 1
#define MDI_MODE 2
#define MANUAL_MODE 3
//译码模块的状态
typedef int TASK_INTERP_STATE;
#define TASK_INTERP_IDLE 1
#define TASK_INTERP_EXEC 2
#define TASK_INTERP_PAUSED 3
#define TASK_INTERP_WAITING 4
//任务执行的状态
typedef int TASK_EXEC_STATE;
#define TASK_EXEC_DONE 1
#define TASK_EXEC_WAITING_FOR_MOTION  2
#define TASK_EXEC_WAITING_FOR_IO  3
#define TASK_EXEC_WAITING_FOR_MOTION_IO 4
#define TASK_EXEC_WAITING_FOR_PAUSE 5
#define TASK_EXEC_WAITING_FOR_MOTION_QUEUE 6
#define TASK_EXEC_ERROR 7

//运动控制模块
#define CMD_FIFO          1
#define STATUS_FIFO     2
#define ERROR_FIFO       3
#define FIFO_BUFFER_NUM     20
//#define BUFFER_NUM     40

//插补算法
#define CHORD 1
                  //内接弦线法
#define DDA 2
                 //扩展dda法
#define IN_OUT_CHORD 3
               //内外均差法

#define CMD_ARRAY_LACK_NUM 500
#define INTERPRET_CODE_NUM 500
//#ifdef __cplusplus
//extern "C"
//{
//#endif

typedef struct CNC_CARTESIAN_STRUCT    //直角坐标点结构体
{
	double x,y,z;
}
CartesianStruct;

typedef struct CNC_POSE_STRUCT          //空间坐标点结构体
{
	CartesianStruct tran;
    //double a, b, c;
	//
}
PoseStruct;

//系统配置结构体
typedef struct CNC_BASE_CONFIG_STRUCT  //基本信息配置  根据ini文件配置有所变动
{
	char vertion[LINE_LEN];
	char machine[LINE_LEN];
	char nmlFile[LINE_LEN];
}
BaseConfigStruct;

typedef struct CNC_TRAJ_CONFIG_STRUCT  //坐标系统配置
{
	int axes;
	char coordinates[10];
	PoseStruct home;
	char linearUnit[LINE_LEN];
	char angularUnit[LINE_LEN];
	double cycleTime;
	double defaultVel;
	double maxVel;
	double defaultAcc;
	double maxAcc;
}
TrajConfigStruct;
typedef struct CNC_AXIS_CONFIG_STRUCT   //轴配置
{
	int type;
	double home;
	double maxVel;
	double maxAcc;
}
AxisConfigStruct;
typedef struct CNC_DISP_CONFIG_STRUCT    //GUI模块配置
{
	
}
DispConfigStruct;
typedef struct CNC_TASK_CONFIG_STRUCT    //任务管理模块配置
{
	char name[LINE_LEN];
	double cycleTime;
}
TaskConfigStruct;
typedef struct CNC_INTERP_CONFIG_STRUCT  //译码模块配置
{
	char name[LINE_LEN];
	char defaultCodeFile[LINE_LEN];
	char parFile[LINE_LEN];
}
InterpConfigStruct;
typedef struct CNC_MOTION_CONFIG_STRUCT  //运动控制模块配置
{
	char name[LINE_LEN];
	double baseTime;
	double trajCycleTime;            //插补周期
	double servoCycleTime;	       //伺服周期
	int arithmetic;
	int accControl;
}
MotionConfigStruct;
typedef struct CNC_IO_CONFIG_STRUCT    //IO控制模块配置
{
	char name[LINE_LEN];
	double cycleTime;
	char cutterFile[LINE_LEN];
	CartesianStruct cutterChangePos;
}
IoConfigStruct;

typedef struct CNC_INI_CONFIG_STRUCT  //配置文件结构体
{
	BaseConfigStruct baseConfig;
	TrajConfigStruct trajConfig;
	AxisConfigStruct axisConfig_1;
	AxisConfigStruct axisConfig_2;
	AxisConfigStruct axisConfig_3;
	DispConfigStruct dispConfig;
	TaskConfigStruct taskConfig;
	InterpConfigStruct interpConfig;
	MotionConfigStruct motionConfig;
	IoConfigStruct ioConfig;
}
IniConfigStruct;

typedef enum       //运动控制命令 （任务管理模块发送给运动控制模块的命令，不完全）
{
	MOTION_START = 1, //启动
	MOTION_ABORT,	//停止
	MOTION_PAUSE,		//暂停
	MOTION_RESUME,		//暂停后开始
	MOTION_STEP,		//单步运行
	MOTION_LINE,	//直线插补
	MOTION_CIRCLE,	//圆弧插补
	MOTION_SET_VEL,		//设置速度
	MOTION_SET_VEL_LIMIT,	//设置速度限位
	MOTION_SET_SPINDLE_VEL,	//设置主轴转速,>0为正转 反之
	MOTION_SPINDLE_ON,	//启动主轴
	MOTION_SPINDLE_OFF,	//停止主轴

	MOTION_SET_CONIFIG,  //配置命令
	MOTION_END                //程序结束
} 
MOTION_CMD_TYPE;

typedef enum     //运动控制命令的执行状态
{
	MOTION_CMD_OK = 0,       //成功
	MOTION_CMD_UNKNOWN,	//未知错误
	MOTION_CMD_INVALID,	    //不能马上处理
	MOTION_CMD_PARAMS_INVALID,	//命令参数有误
	MOTION_CMD_EXEC_ERROR	//执行错误
}
 MOTION_CMD_STATUS;

 typedef struct CNC_SPINDLE_STATUS  //主轴状态
{
	double speed;		// spindle speed in RPMs
	int direction;		// 0 stopped, 1 forward, -1 reverse
	int brake;		// 0 released, 1 engaged   制动状态
}
SpindleStatus;

//粗插补状态
#define INTERP_RUNNING 0
#define INTERP_FINISH 1
#define INTERP_END 2
typedef struct CNC_INTERPOLATION_STATUS  //粗插补状态结构体
{ 
	PoseStruct startPt;      //起点
	PoseStruct endPt;      //终点
	PoseStruct arrPt;      //当前点.
	PoseStruct relArrPt;      // 当前点相对坐标
	PoseStruct increment;    // 增量
	
	int      period;	//插补周期
	double  realF;   //实际速度
	double  planF;  //命令速度
	double acc;      //加速度
	int	   interpNum;  //插补次数
	int   status;         //插补状态
	double debugData;  //调试用
}InterpStatusStruct;  


typedef struct CNC_LINE_INTERP_PARA      //直线插补参数结构体
{
	PoseStruct startPt;    //起点
	PoseStruct endPt;     //终点
	double cosValMax;  //与水平夹角最大cos值
	double dx;            //x方向增量
	double dy;       //y方向增量
	double dz;       //z方向增量
	double dmax;   //合成最大增量
	//double decDistance;
	double distance; //行程
	int  stepNum;   //步数
}
LineParaSturct;

typedef struct CNC_CIRCLE_INTERP_PARA    // 圆弧插补参数结构体
{
	PoseStruct startPt;      //起点
	PoseStruct endPt;     //终点
	PoseStruct relStartPt;   //相对起点
	PoseStruct relEndPt;    //相对终点
	CartesianStruct normal;     //法向
	CartesianStruct center;   //圆 心
	double  r;              //半径
	int direction;    //g02:  1  g03: -1 方向
	int plane; // 0 xy  圆弧平面
	double stepLen;  //步长
	double distanceToEnd;   //距离终点的距离
	int signx;                     //符号
	int signy;                   //符号
	int sietaFlag;            //优劣弧
}
CircleParaStruct;

typedef struct CNC_MOTION_CMD_STRUCT   //运动控制命令结构体
{
	unsigned char head;	//数据头
	MOTION_CMD_TYPE command;	//命令类型
	int motionType;        //运动类型
	int commandNum;		//命令序列号
	PoseStruct endPt;		//终点
	CartesianStruct center;	//圆弧圆心
	CartesianStruct normal;	//圆弧法向
	int line;                         //程序段号
	int turn;		                    //圆弧方向
	double vel;		//进给速度
	double maxVel;     //最大进给速度
	double acc;		//加速度
	double backlash;	//游隙，死区
	MotionConfigStruct motionConfig; //运动模块配置命令
	unsigned char tail;	//数据尾
}
MotionCmdStruct;

typedef struct CNC_MOTION_STATUS_STRUCT  //运动控制状态
{
	unsigned char head;	//数据头

	MOTION_CMD_TYPE command;	//命令类型
	int commandNum;	//命令号
	MOTION_CMD_STATUS commandStatus;	//命令执行状态
	int line;                      //当前执行的程序段号
	int enableNewMotion;  //是否允许新的进给运动
	PoseStruct cmdPos;	//命令位置
	PoseStruct actualPos;	//实际位置
	PoseStruct incrementPos;	//增量
	SpindleStatus spindleStatus;	//主轴状态
	InterpStatusStruct interpStatus;  //插补状态
	int pauseFlag;		//暂停标志
	double cycleTime;		//插补周期
	int arrayNum;			//命令缓冲区命令数
	int arrayIndex;		// 命令缓冲区当前号
	int arrayInterpIndex;		//命令缓冲区当前命令号
	double vel;	            //速度
	double cmdVel;	        //命令速度
	double acc;		        //加速度
	int motionType;         //运动类型
	double distance;        //本段程序运行距离
	int cmdArrayFullFlag;  //命令缓冲区是否已满
	
	//test
	CartesianStruct center;	//圆弧圆心
	CartesianStruct normal;	//圆弧法向方向
	CircleParaStruct circlePara;
	int turn;                      
	unsigned char tail;	//数据尾
}
MotionStatusStruct;

typedef struct CNC_MOTION_ERROR_STRUCT   //运动控制错误结构体
{
	unsigned char head;	//数据头
	char error[BUFFERLEN][LINE_LEN];  //错误文本
	//...
	unsigned char tail;	//数据尾
}
MotionErrorStruct;


#ifdef OUTPUT
#define INC_NUM 1000
#define SHM "output"
typedef struct CNC_OUTPUT_STRUCT
{
	unsigned char head;	
	unsigned char readFlag;		
	PoseStruct increment[INC_NUM];
	int index;
	int num;
	unsigned char tail;	
}
OutputStruct;
#endif
						
//#ifdef __cplusplus
//}
//#endif

#endif  //CNC_H
