library(ggplot2)
library(genpwr)
library(dplyr)

# INSERT THE CASE NUMBERS HERE
GP_cases=8793 # THIS SHOULD BE EXCLUDING PEOPLE THAT ARE NOT IN THE GP RECORDS AT ALL
HES_cases=2998

HGtheme=theme_bw()+theme(axis.line = element_line(colour = "black"),panel.grid.minor = element_blank(),panel.background = element_blank(),plot.title = element_text(hjust = 0.5))

gppw <- genpwr.calc(calc = "power", model = "logistic", ge.interaction = NULL,
                  N=209832, Case.Rate=GP_cases/209832, k=NULL,
                  MAF=seq(0.001, 0.03, 0.001), OR=c(1.5,2,3),Alpha=1e-9,
                  True.Model="Additive", 
                  Test.Model="Additive")
gp_power=power.plot(gppw,panel.by = 'OR',return_gg=T)[[1]]+HGtheme+ggtitle('Power in GP Records')+ylab('Power')
ggsave(filename = "GP_power.png", plot = gp_power, width = 10, height = 4, dpi = 300)

hespw <- genpwr.calc(calc = "power", model = "logistic", ge.interaction = NULL,
                  N=451229, Case.Rate=HES_cases/451229, k=NULL,
                  MAF=seq(0.001, 0.03, 0.001), OR=c(1.5,2,3),Alpha=1e-9,
                  True.Model="Additive", 
                  Test.Model="Additive")
hes_power=power.plot(hespw,panel.by = 'OR',return_gg=T)[[1]]+HGtheme+ggtitle('Power in HES Records')+ylab('Power')
ggsave(filename = "HES_power.png", plot = hes_power, width = 10, height = 4, dpi = 300)

all_pw=rbind(as.data.frame(hespw)%>%mutate(source='HES'),as.data.frame(gppw)%>%mutate(source='GP'))%>%mutate(MAF=MAF*100)

all_power=ggplot(all_pw, aes(x = MAF, y = `Power_at_Alpha_1e-09`, color = source)) +
    geom_line() + # Use geom_line() to connect points with lines
    geom_point(shape = 21, size = 4, fill = "white") +
    facet_wrap(~ OR, scales = 'free', labeller = labeller(OR = function(x) paste("OR =", x))) + # Custom facet labels
    HGtheme + # Optional: Use a minimal theme for a cleaner look
    labs(x = "MAF (%)", y = "Power", title = "Power by MAF and OR", color = "Source")
ggsave(filename = "All_power.png", plot = all_power, width = 10, height = 4, dpi = 300)
