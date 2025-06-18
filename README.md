# 🧮 T4 – Sistemas Digitais: Aritmética de Ponto Flutuante

## 🎯 Objetivo

Este projeto tem como objetivo **elucidar o papel do padrão IEEE-754** na implementação de hardware para unidades de ponto flutuante (FPUs). Além disso, busca evidenciar os **trade-offs de projeto** ao trabalhar com diferentes tamanhos de mantissa e expoente, definidos individualmente para cada aluno com base na sua matrícula.

---

## 🧩 Visão Geral do Projeto

O sistema desenvolvido consiste em uma **FPU extremamente simplificada**, capaz de realizar **operações de soma** entre dois operandos de 32 bits com uma codificação personalizada de ponto flutuante.

### Principais módulos:

- 🧮 **FPU (Floating Point Unit)**  
  Opera com um **clock de 100 kHz** e **reset assíncrono ativo em nível baixo**.  
  Realiza operações de soma e subtração entre as entradas `op_A_in` e `op_B_in`, fornecendo o resultado em `data_out` com um sinal de status `status_out`, responsável por expor informações adicionas sobre o resultado da operação.

---

## 🔢 Codificação Personalizada de Operandos

Cada aluno possui um padrão único de codificação de operandos baseado em sua matrícula.

### Estrutura de cada operando (32 bits):

| Bit | Descrição            |
|---- |----------------------|
| 31  | Sinal (1 bit)        |
| X   | Expoente (X bits)    |
| Y   | Mantissa (Y bits)    |

- **Sinal:** Segue o padrão IEEE-754.
- **Expoente (X bits):** Calculado com base na fórmula:
  
  X = [8 (+/-) (∑b mod 4)]
  
Onde:

- ∑b = soma de todos os dígitos da matrícula (exceto o dígito verificador).
- Mod 4 = resto da divisão por 4.
- O sinal da operação (+ ou -) depende do dígito verificador da matrícula:
  - Se for ímpar → **soma**
  - Se for par → **subtrai**

- **Mantissa (Y bits):** Calculada como:

  Y = 31 - X

📌 **Cálculo de X e Y:**

A matrícula utilizada foi **???**, então: 

 X = 10
 Y = 21

---

## ✅ Status da Operação (`status_out`)

O sinal `status_out` possui **4 bits** para indicar o estado do resultado:

| Bit  | Estado       | Descrição                                          |
|----  |------------- |--------------------------------------------------- |
| 0    | EXACT        | Resultado exato, sem necessidade de arredondamento |
| 1    | OVERFLOW     | Resultado excedeu o intervalo representável        |
| 2    | UNDERFLOW    | Resultado menor que o menor valor representável    |
| 3    | INEXACT      | Resultado sofreu arredondamento                    |

---

## ▶️ Execução do Projeto

A simulação foi feita utilizando o **QuestaSim**.

### Passo a passo:

1. Abra o terminal e navegue até a pasta do projeto.
2. Execute o seguinte comando para iniciar a simulação:

```tcl
do sim.do
```

- O script ***sim.do*** compila todos os arquivos necessários e inicia a visualização das formas de onda.

