

###  Proyecto de Segmentación de Clientes con KModes ###

###  Cristian Riquelme F. ##


# Carga de librerías
library(klaR)      
library(tidyverse)
library(tidyr)
set.seed(123)


# Carga de datos

df <- read.csv('marketing_campaign.csv', sep='\t', stringsAsFactors = FALSE)


# 1.PREPROCESAMIENTO SOCIOLÓGICO (FEATURE ENGINEERING)

# A. Limpieza
df <- na.omit(df)

# B. Edad
if("Year_Birth" %in% names(df)) {
  df$Edad <- 2025 - df$Year_Birth
} else { df$Edad <- 45 }
df <- df[df$Edad < 100, ]

# C. Estado Civil
mapa_civil <- c('Married'='Pareja', 'Together'='Pareja', 'Single'='Soltero', 
                'Divorced'='Soltero', 'Widow'='Soltero', 'Alone'='Soltero', 
                'Absurd'='Soltero', 'YOLO'='Soltero')

if("Marital_Status" %in% names(df)) {
  df$Estado_Civil <- dplyr::recode(df$Marital_Status, !!!mapa_civil, .default = "Desconocido")
} else { df$Estado_Civil <- 'Desconocido' }

# D. ESTRUCTURA FAMILIAR
# Convertimos a numérico y forzamos ceros
df$Kidhome <- as.numeric(df$Kidhome)
df$Kidhome[is.na(df$Kidhome)] <- 0
df$Teenhome <- as.numeric(df$Teenhome)
df$Teenhome[is.na(df$Teenhome)] <- 0

# Variables auxiliares
df$Total_Hijos <- df$Kidhome + df$Teenhome
df$Es_Pareja <- (df$Estado_Civil == 'Pareja')

# Creación de categoría
df <- df %>%
  mutate(
    Family_Structure = case_when(
      Total_Hijos == 0 & Edad > 55 ~ 'Empty_Nesters',
      Total_Hijos == 0 & Es_Pareja ~ 'Couple_NoKids',
      Total_Hijos == 0 & !Es_Pareja ~ 'Single_NoKids',
      Kidhome > 0 ~ 'Family_YoungKids',
      Teenhome > 0 ~ 'Family_Teens',
      TRUE ~ 'Family_Mixed'
    )
  )

# E. Otras Variables
df <- df %>%
  mutate(
    Generacion = case_when(
      Edad < 30 ~ 'Gen Z', Edad < 45 ~ 'Millennial', 
      Edad < 60 ~ 'Gen X', TRUE ~ 'Boomer'
    ),
    Nivel_Ingreso = case_when(
      ntile(Income, 4) == 1 ~ 'Bajo', ntile(Income, 4) == 2 ~ 'Medio-Bajo',
      ntile(Income, 4) == 3 ~ 'Medio-Alto', TRUE ~ 'Alto'
    )
  )

# Engagement y Educación
cols_campanas <- c('AcceptedCmp1', 'AcceptedCmp2', 'AcceptedCmp3', 'AcceptedCmp4', 'AcceptedCmp5', 'Response')
existen <- intersect(names(df), cols_campanas)
if(length(existen) > 0) {
  df$Total_Accepted <- rowSums(df[, existen, drop=FALSE])
} else { df$Total_Accepted <- 0 }

df$Engagement <- case_when(df$Total_Accepted == 0 ~ 'Pasivo', 
                           df$Total_Accepted <= 2 ~ 'Selectivo', TRUE ~ 'Fanatico')

mapa_edu <- c('Basic'='Bajo', '2n Cycle'='Medio', 'Graduation'='Medio', 'Master'='Alto', 'PhD'='Alto')
df$Nivel_Educacion <- dplyr::recode(df$Education, !!!mapa_edu, .default = "Desconocido")


# 2.PREPARACIÓN MODELO 

cols_modelo <- c('Family_Structure', 'Generacion', 'Nivel_Ingreso', 'Engagement', 'Nivel_Educacion')

# Usamos df[, cols] en lugar de select(). 
df_model <- df[, cols_modelo]

# Convertimos todo a factores explícitamente
df_model[] <- lapply(df_model, as.factor)

cat("\n--- Verificación (Debe decir 'Factor' en todas las vars) ---\n")
print(str(df_model)) 


# 3.EJECUCIÓN K-MODES

cat("\nEjecutando K-Modes...\n")
set.seed(123)

# Algoritmo
km_final <- kmodes(df_model, modes = 3, iter.max = 10, weighted = FALSE)

# Guardamos resultados
df_final <- df
df_final$Cluster_Label <- as.factor(km_final$cluster)


# 4.RESULTADOS

cat("\nRESULTADOS FINALES (Centroides):\n")
print(km_final$modes)

# Gráfico por estructura familiar
ggplot(df_final, aes(x=Cluster_Label, fill=Family_Structure)) +
  geom_bar(position="dodge") +
  scale_fill_brewer(palette = "Set2") +
  theme_minimal() +
  labs(title="Segmentación Final de Clientes", x="Cluster", y="Personas")

# Gráfico opr generación etárea
ggplot(df_final, aes(x=Cluster_Label, fill=Generacion)) +
  geom_bar(position="dodge") +
  scale_fill_brewer(palette = "Set2") +
  theme_minimal() +
  labs(title="Segmentación Final de Clientes", x="Cluster", y="Personas")


# VISUALIZACIÓN AVANZADA (FACET GRID)
datos_plot <- df_final %>%
  dplyr::select(Cluster_Label, Family_Structure, Generacion, Nivel_Ingreso, Engagement) %>%
  pivot_longer(cols = -Cluster_Label, names_to = "Variable", values_to = "Categoria")

# Gráfico
ggplot(datos_plot, aes(x = Categoria, fill = Cluster_Label)) 
  geom_bar(position = "fill") +        
  facet_wrap(~Variable, scales = "free", ncol = 2) + 
  coord_flip() +                       
  scale_fill_brewer(palette = "Set1") +
  labs(title = "ADN de los Segmentos",
       subtitle = "Proporción de cada Clúster dentro de cada categoría sociológica",
       x = "Categoría", 
       y = "Proporción (%)", 
       fill = "Clúster") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 0))


# 5.Validación estadística con Chi-cuadrado
# Vamos a probar si las variables dependen estadísticamente del Cluster

vars_interes <- c('Family_Structure', 'Generacion', 'Nivel_Ingreso', 'Engagement')

cat("\n--- Pruebas de Independencia Chi-Cuadrado ---\n")
for(var in vars_interes){
  
  tbl <- table(df_final$Cluster_Label, df_final[[var]])
  test <- chisq.test(tbl)
  p_val <- test$p.value
  significancia <- if(p_val < 0.05) "SIGNIFICATIVO" else "NO SIGNIFICATIVO"
  
  cat(sprintf("Variable: %-20s | P-Value: %.5f | Resultado: %s\n", var, p_val, significancia))
}
  
#Esto confirma que los clústeres no son aleatorios. Las variables que elegimos 
#(Familia, Generación, Ingreso, Engagement) son determinantes. Existe una dependencia 
#fortísima entre pertenecer a un clúster y tener cierta estructura familiar o nivel de ingreso. 
#Hemos encontrado patrones reales, no coincidencia.
  


# 6.ANÁLISIS DE SILUETA (Validación de Cohesión)
# =============================================

# Instalamos la librería 'cluster'
if(!require(cluster)) install.packages("cluster")
library(cluster)

cat("\nCalculando Análisis de Silueta\n")

# Calcular Matriz de Disimilitud (Distancia de Gower)
# Usamos 'metric = "gower"' porque es la correcta para variables tipo FACTOR
distancia_gower <- daisy(df_model, metric = "gower")

# Calcular el objeto Silueta usando los clústeres de tu modelo (km_final)
silueta <- silhouette(km_final$cluster, distancia_gower)

# Graficar
# Ajustamos márgenes para que se vea bien
par(mar = c(5, 2, 4, 2)) 
plot(silueta, 
     col = c("#E41A1C", "#377EB8", "#4DAF4A"),
     border = NA,
     main = "Gráfico de Silueta - Segmentación K-Modes",
     xlab = "Ancho de Silueta (Cohesión)",
     sub = paste("Promedio General =", round(mean(silueta[, 3]), 2)))

# El comportamiento humano es complejo y aquí tenemos dos grupos definidos y uno difuso


# Interpretación Numérica
cat("\n--- Interpretación de la Silueta ---\n")
promedio_silueta <- mean(silueta[, 3])
cat(sprintf("Promedio de Silueta General: %.3f\n", promedio_silueta))

if(promedio_silueta > 0.5){
  cat("CONCLUSIÓN: Estructura fuerte. Los grupos están muy bien definidos.\n")
} else if(promedio_silueta > 0.25){
  cat("CONCLUSIÓN: Estructura razonable. Hay patrones, aunque algunos datos son ambiguos.\n")
} else {
  cat("CONCLUSIÓN: Estructura débil. Los grupos se solapan bastante (común en datos sociológicos).\n")
}



# 7.EXPORTACIÓN DE RESULTADOS
# Guardamos la base etiquetada para enviarla a Excel

write.csv(df_final, "Clientes_Segmentados_Final.csv", row.names = FALSE)
