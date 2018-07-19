server<-shinyServer(function(input, output, session) {
  
  observe({
    
    val<-input$SOURCE
    
    if(is.null(val)) {
      return('Null')
    }
    
    val<-fread(val$datapath)
    val<-val$Time %>% as.POSIXct('%Y-%m-%d %H:%M:%S', tz = 'UTC')
    val<-c(min(val), max(val))
    
    updateSliderInput(session, "Trange", value = c(val[1],val[2]),
                      min = val[1], max = val[2], step = 1)
    
    visdata<-reactive({
      
      rawpath<-input$SOURCE
      
      if(is.null(rawpath)) {
        return('Null')
      }
      
      TLmin<-input$Trange[1]
      TLmax<-input$Trange[2]
      
      raw<-fread(rawpath$datapath)[,Time:=as.POSIXct(Time, '%Y-%m-%d %H:%M:%S', tz = 'UTC')][,Speed:=Speed/3.6]
      raw<-raw[,Time:= Time - hours(8)]# Time adjust
      raw<-raw[Time >= (TLmin - hours(8)) & Time <= (TLmax - hours(8))]# Time adjust
      
    })
    
    visplot<-reactive({
      
      visdata %>%
        ggvis(x = ~Time, y = ~Speed) %>%
        layer_points(size := 10) %>%
        scale_datetime('x',
                       utc = FALSE,
                       nice = 'second') %>%
        set_options(width = 950, height = 350)
      
    })
    
    visplot %>% bind_shiny('plot1')
    
    #===================================plot2========================================================    
    
    output$plot2<-renderPlot({
      
      rawpath<-input$SOURCE
      
      if(is.null(rawpath)) {
        return('Null')
      }
      
      Tnod1<-as.POSIXct(input$Tnode1, '%Y-%m-%d %H:%M:%S', tz = 'UTC')
      Tnod2<-as.POSIXct(input$Tnode2, '%Y-%m-%d %H:%M:%S', tz = 'UTC')
      
      raw<-fread(rawpath$datapath)[,Time:=as.POSIXct(Time, '%Y-%m-%d %H:%M:%S', tz = 'UTC')][,Speed:=Speed/3.6]
      raw<-raw[Time >= Tnod1 & Time <= Tnod2]
      
      #=============================base data==============================================
      
      #定义bin
      ##MOVES2014 bin定义編輯區(不包括Bin1)
      Speedminnode<-c(-Inf,0.44704,0.44704,0.44704,0.44704,0.44704,0.44704,11.1760,11.1760,11.1760,11.1760,11.1760,11.1760,11.1760,11.1760,11.1760,22.3520,22.3520,22.3520,22.3520,22.3520,22.3520)
      Speedmaxnode<-c(0.44704,11.1760,11.1760,11.1760,11.1760,11.1760,11.1760,22.3520,22.3520,22.3520,22.3520,22.3520,22.3520,22.3520,22.3520,22.3520,Inf,Inf,Inf,Inf,Inf,Inf)
      VSPminnode<-c(-Inf,-Inf,0,3,6,9,12,-Inf,0,3,6,9,12,18,24,30,-Inf,6,12,18,24,30)
      VSPmaxnode<-c(Inf,0,3,6,9,12,Inf,0,3,6,9,12,18,24,30,Inf,6,12,18,24,30,Inf)
      Node<-data.table(VSPmin=VSPminnode,
                       VSPmax=VSPmaxnode,
                       vmin=Speedminnode,
                       vmax=Speedmaxnode)
      Node<-Node[,BIN:=as.character(paste('bin',2:23,sep = ''))]
      Node<-as.data.frame(Node)
      #end
      
      
      #BIN匹配模板
      Btable<-data.table(BIN=as.character(paste('bin',1:23, sep = '')),
                         cnt=0)
      #end
      
      #BIN加权平均函数
      FUNweight<-function(x){weighted.mean(x,subraw$Fweight)}
      
      #end
      
      
      #=============================base data end==============================================
      
      #=============================statistic argument=========================================
      
      #index input
      
      fueltype<-input$CarFuel#user setting
      carweight<-input$CarGVW #unit:ton #user setting
      wei.type<-ifelse(carweight<3.5, '1', ifelse(carweight>=3.5 & carweight<12, '2', 3))
      reg.type<-input$CarReg#user setting
      old.type<-ifelse(input$CarOdo<=79000, '1', ifelse(input$CarOdo>79000 & input$CarOdo<=161000, '2', ifelse(input$CarOdo>161000, '3', '1')))#defult
      Id.sample<-paste0(fueltype,wei.type,reg.type,old.type)
      
      
      #=============================select subsample end===============================================
      
      
      #=============================bin colculate======================================================
      
      ##time diff calculate
      raw<-raw[,Dtime:=c(0,difftime(Time[2:length(Time)],Time[1:(length(Time)-1)]) %>% as.numeric())]
      
      ##calculate acceleration(av1,av2,av3) and VSP
      
      raw<-raw[,av1:=list(c(0,diff(Speed)/as.numeric(difftime(Time[2:length(Time)],Time[1:(length(Time)-1)]))))]
      raw<-raw[,c('av2','av3'):=list(c(0,av1[1:(length(av1)-1)]), c(0,0,av1[1:(length(av1)-2)]))]
      raw<-raw[,c('h.delta','Vsum'):=list(c(0,diff(Altitude)),c(Speed+c(0,Speed[1:(length(Speed)-1)])))][,sinthita:=2*h.delta/(Vsum*Dtime)]
      raw<-raw[,sinthita:=c(0,sinthita[2:length(sinthita)])][,sinthita:=ifelse(sinthita>=1,0,sinthita)][,!c('h.delta','Vsum')]
      raw<-raw[,carweight:=carweight]
      raw<-raw[,VSP:='Unknown']
      raw<-within(raw,{
        VSP[carweight<=3.855]<-(0.156461*Speed+0.00200193*Speed^2+0.000492646*Speed^3+carweight*Speed*(av1+9.81*sinthita))/1.4788#MOVES2009
        VSP[3.855<carweight&carweight<=6.350]<-(0.0996*carweight*Speed+(0.00289+5.22*(10^-5)*carweight)*Speed^3+carweight*Speed*(av1+9.81*sinthita))#MOVES2014
        VSP[6.350<carweight&carweight<=14.968]<-(0.0875*carweight*Speed+(0.00193+5.9*(10^-5)*carweight)*Speed^3+carweight*Speed*(av1+9.81*sinthita))#MOVES2014
        VSP[14.968<carweight]<-(0.0661*carweight*Speed+(0.00289+4.21*(10^-5)*carweight)*Speed^3+carweight*Speed*(av1+9.81*sinthita))#MOVES2014
      })
      
      raw<-raw[,VSP:=as.numeric(VSP)]
      
      #define BIN
      raw<-raw[,BIN:='Unknown']
      for(k in 1:length(Node$BIN)){
        raw<-within(raw,{
          BIN[VSP>=Node[k,1]&VSP<Node[k,2]&Speed>=Node[k,3]&Speed<Node[k,4]]<-Node[k,5]
        })
      }
      
      raw<-raw[,BIN:=ifelse(av1 <= -0.89408, 'bin1',
                            ifelse( av1 < -0.44704 & av2 < -0.44704 & av3 < -0.44704, 'bin1', BIN))]
      
      raw<-raw[,c('Time','Speed','Altitude','BIN')]
      
      #=============================bin colculate end======================================================
      
      
      
      #=============================emission colculate=====================================================
      
      ##ef data
      EF<-fread('F:/dengfanyuan/drivesoftware/www/mapping.csv', colClasses = c('character','character','character','numeric'))[,c('Index','BIN'):=list(paste0(Index,1), paste0('bin',Bin))][,!c('Bin')]
      
      ##set pollutant
      
      PT<-input$CarPt#user setting
      
      ##sub ef data
      
      subEF<-EF[Index == Id.sample & Species == PT][,!c('Species','Index')]
      
      
      ##calculate BIN freq. in raw
      
      raw2<-raw[,.(Freq = .N), by = 'BIN'] %>% merge(Btable, by = 'BIN', all.y = TRUE)
      raw2<-raw2[,!c('cnt')]
      raw2[is.na(raw2)]<-0
      raw2<-raw2[,Freq:=Freq/sum(Freq)]
      
      #calculate emission
      
      raw2<-merge(raw2,subEF, by = 'BIN', all.x = TRUE)[,emission:=ef*Freq*as.numeric(difftime(Tnod2,Tnod1, units = 'sec'))]
      
      TEM<-sum(raw2$emission)
      
      #=============================emission colculate end=====================================================
      
      #=============================plot=======================================================================
      
      raw2<-raw2[,BIN:=factor(BIN, levels = paste0('bin',c(1:23)))]
      
      p1<-ggplot(raw2, aes(x = BIN, y = emission))+
        geom_bar(aes(fill = Freq*100),stat = 'identity', color = 'black')+
        scale_x_discrete()+
        scale_y_continuous(name = paste(PT,'emission (g)'))+
        scale_fill_continuous(name = 'Time destribution (%)')+
        labs(title = paste('Total',PT,'emission:',round(TEM,3),'g'),
             subtitle = paste('Start:', Tnod1, '/', 'End:', Tnod2))+
        theme(panel.background = element_rect(fill = NA, color = 'black', size = 1),
              panel.border = element_rect(fill = NA, color = 'black', size = 1),
              panel.grid = element_blank(),
              axis.title.y = element_text(size = 20, face = 'bold', color = 'black', vjust = 3),
              axis.title.x = element_blank(),
              axis.text = element_text(size = 16, face = 'bold', color = 'black'),
              legend.title = element_text(size = 20, face = 'bold', color = 'black'),
              legend.text = element_text(size = 16, face = 'bold', color = 'black'),
              legend.position = 'bottom',
              legend.key.width = unit(3, units = 'cm'),
              plot.title = element_text(size = 24, face = 'bold', color = 'black'),
              plot.subtitle = element_text(size = 22, face = 'bold.italic', color = 'gray30'))
      
      print(p1)
      
    })
    
    
  })
  
  
})
