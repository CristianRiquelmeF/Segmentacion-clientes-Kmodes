

 Proyecto de Segmentación de Clientes con KModes
 Descripción del Proyecto

Este proyecto implementa un algoritmo de segmentación de clientes utilizando K-Modes, una variante del algoritmo K-Means diseñada para datos categóricos. 
El análisis se basa en datos de marketing que permiten identificar patrones sociológicos diferenciados para optimizar la estrategia de comunicación y permitir estrategias de marketing personalizadas.


 Metodología Técnica
    Fuente de Datos: Base de marketing con 2,200+ registros.
    R (Lenguaje de programación estadística)
    klaR (Paquete para algoritmo K-Modes)
    tidyverse (dplyr, ggplot2 - manipulación y visualización)
    Clustering con algoritmo K-Modes (específico para variables categóricas).
    Validación: Estadística inferencial (Pruebas Chi-Cuadrado) y Análisis de Silueta de Gower.

Estructura del Script

 Preprocesamiento Sociológico (Feature Engineering)

    Limpieza de datos (eliminación de NA)
    Creación de variables derivadas:
        Edad a partir del año de nacimiento
        Estado Civil recodificado
        Estructura Familiar (Empty_Nesters, Couple_NoKids, etc.)
        Generación (Gen Z, Millennial, Gen X, Boomer)
        Nivel de Ingreso (cuartiles)
        Engagement (Pasivo, Selectivo, Fanático)
        Nivel de Educación
. Preparación del Modelo

    Selección de variables categóricas para clustering
    Conversión explícita a factores
    Verificación de estructura de datos

 Ejecución de K-Modes

    Configuración: 3 clusters, 10 iteraciones máximas
    Implementación del algoritmo
    Asignación de etiquetas de cluster

  <img width="665" height="250" alt="Rplot01" src="https://github.com/user-attachments/assets/07641577-e7a2-4378-a36b-255f4926accf" />

  <img width="635" height="213" alt="Rplot" src="https://github.com/user-attachments/assets/9d3a3923-19dc-4879-a807-b9ec39d42f1f" />

  <img width="597" height="343" alt="Facet_Grid" src="https://github.com/user-attachments/assets/3882e997-e768-406f-be51-feb4ca9932e2" />


  Validación Estadística

    Pruebas de Chi-Cuadrado para verificar dependencia entre clusters y variables

    Evaluación de significancia estadística (p-value < 0.05). 
    Los valores P cercanos a 0 indican que las diferencias entre grupos son reales y significativas.


   <img width="876" height="211" alt="chi-cuadrado" src="https://github.com/user-attachments/assets/2017006b-0ef3-4999-a02a-4a02bafb8a44" />


  Análisis de Silueta (Cohesión)

Evaluamos qué tan bien definidos están los grupos sociológicamente.

<img width="842" height="343" alt="GrSiluetas" src="https://github.com/user-attachments/assets/e0bb371d-c75f-4fb0-8c01-fd577c1b6512" />

Interpretación: El análisis muestra un promedio de r round(mean(silueta[,3]), 2). Sociológicamente, esto indica la existencia de dos núcleos duros de comportamiento (Clústeres 2 y 3) altamente accionables, y un grupo más disperso (Clúster 1) que representa a la audiencia generalista.


## Requisitos
- R >= 4.0.0
- Paquetes: klaR, tidyverse

## Instalación
```r
install.packages(c("klaR", "tidyverse"))


## Uso
source("KModes.R")



    
   
    
