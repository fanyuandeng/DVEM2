ui<-dashboardPage(
  
#  dashboardHeader(title = h4(strong('交通大数据机动车排放分析模型')),
  dashboardHeader(title = h4(strong('船舶高分辨率排放清单及分析模型')),                  
                  titleWidth = 300),
  dashboardSidebar(width = 300,
                   sidebarMenu(
                     menuItem(strong("首页"), tabName = 'homepage', selected = TRUE, icon = icon('home')),
                     menuItem(strong('文件/参数输入'), tabName = 'FAinput', icon = icon('gear')),
                     menuItem(strong('分析结果输出'), tabName = 'PDoutput', icon = icon('bar-chart-o'))
                   )),
  dashboardBody(
    tags$p(
      tags$style(HTML("
                      
                      p {
                      font-family: '微软雅黑';
                      font-weight: 500;
                      line-height: 1.1;
                      
                      }
                      
                      "))
      ),
    
    tags$strong(
      tags$style(HTML("
                      
                      strong {
                      font-family: '微软雅黑';
                      font-weight: bold;
                      line-height: 1.1;
                      }
                      
                      "))
      ),
    
    tabItems(
      tabItem(tabName = 'homepage',
              fluidPage(
                box(
                  title = strong('欢迎使用'),
                  width = 200,
                  column(
                    img(src="logo.png", height = 200, width = 250),
                    width = 3
                  ),
                  column(
                    p("本软件模型由清华大学环境学院自主开发"),
                    h3('使用步骤'),
                    #p('1.上传轨迹数据源文件(文件/参数输入->上传数据源)'),
                    p('1.上传船舶AIS数据源文件(文件/参数输入->上传数据源)'),
                    #p('2.设置轨迹片段起止时间(文件/参数输入->时间段设置)'),
                    p('2.设置统计时间段起止时间(文件/参数输入->时间段设置)'),
                    #p('3.填写完整车辆信息(文件/参数输入->输入车辆信息)'),
                    p('3.填写统计参数(文件/参数输入->输入统计参数)'),
                    p('4.查看输出结果'),
                    width = 9
                  )
                )
              )
      ),
      
      tabItem(tabName = 'FAinput',
              fluidPage(
                box(
                  title = strong('视图'),
                  width = 300,
                  height = 400,
                  ggvisOutput('plot1')
                ),
                box(
                  title = strong('创建输入数据'),
                  column(width = 3,
                         box(
                           title = strong('上传数据源'),
                           fileInput('SOURCE', label = '格式要求: csv 文件',
                                     width = 300),
                           width = 100,
                           status = 'primary',
                           solidHeader = TRUE
                         )),
                  column(width = 9,
                         tabBox(
                           side = 'left', height = '250px',
                           tabPanel(title = strong('数据总览'),
                                    
                                    sliderInput('Trange', label = '拖动时间条',
                                                min = as.POSIXct('2016-01-01 01:00:00', tz = 'UTC'), 
                                                max = as.POSIXct('2018-08-01 23:00:00', tz = 'UTC'), 
                                                value = as.POSIXct(c('2016-01-01 09:00:00', '2016-01-01 10:00:00'), '%Y-%m-%d %H:%M:%S', tz = 'UTC'), 
                                                width = 600,
                                                timeFormat = '%Y-%m-%d %H:%M:%S',
                                                timezone = '+0000',
                                                step = 1)
                                    
                           ),
                           tabPanel(title = strong('时间段设置'),
                                    column(
                                      width = 6,
                                      box(
                                        title = '1. 开始',
                                        textInput('Tnode1', label = '示例: 2016-01-01 00:00:01'),
                                        width = 100
                                      )
                                    ),
                                    column(
                                      width = 6,
                                      box(
                                        title = '2.结束',
                                        textInput('Tnode2', label = '示例: 2016-01-01 00:00:01'),
                                        width = 100
                                      )
                                    )
                                    
                           ),
                           tabPanel(title = strong('输入车辆信息'),
                                    box(
                                      title = '燃料类型',
                                      selectInput(inputId = 'CarFuel', label = '其他燃料包括天然气、液化石油气等', 
                                                  choices = c('柴油' = '1',
                                                              '汽油' = '2',
                                                              '其他燃料' = '3')),
                                      width = 3
                                    ),
                                    box(
                                      title = '车辆总质量(吨)',
                                      numericInput(inputId = 'CarGVW', label = '可手动输入或通过箭头控件选择',
                                                   value = 1.5, min = 0, max = 200),
                                      width = 3
                                    ),
                                    box(
                                      title = '排放标准',
                                      selectInput(inputId = 'CarReg', label = '请根据车辆合格证信息选择', 
                                                  choices = c('国一前' = '0',
                                                              '国一' = '1',
                                                              '国二' = '2',
                                                              '国三' = '3',
                                                              '国四' = '4',
                                                              '国五' = '5',
                                                              '国六' = '6')),
                                      width = 3
                                    ),
                                    box(
                                      title = '里程表读数(km)',
                                      numericInput(inputId = 'CarOdo', label = '可手动输入或通过箭头控件选择',
                                                   value = 40000, min = 0, max = 20000000),
                                      width = 3
                                    )),
                           width = 200
                         )),
                  width = 300,
                  height = 300
                )
              )
      ),
      
      tabItem(
        
        tabName = 'PDoutput',
        fluidPage(
          column(width = 2,
                 selectInput('CarPt','污染物',
                             c('CO','HC','NOx','PM2.5'))),
          plotOutput('plot2', height = 350)
        )
        
      )
      
    )
      ),
 # skin = 'purple'
 skin = 'red'
      )
